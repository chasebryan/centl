// Zero-JavaScript Web Server for CENTL
// Free Computation Foundation - Apache-2.0

pub mod handler;
pub mod lab_template;
pub mod template;

use crate::engine::{HistoryEntry, Session};
use handler::{handle_command, render_full_page, AppState};
use std::collections::HashMap;
use std::env;
#[cfg(unix)]
use std::ffi::CString;
use std::fs::{self, File, OpenOptions};
use std::io::{self, Read, Write};
use std::net::{TcpListener, TcpStream};
use std::path::{Component, Path, PathBuf};
use std::sync::atomic::{AtomicU64, Ordering};
use std::sync::{Arc, Mutex};
use std::thread;
use std::time::{Duration, Instant, SystemTime, UNIX_EPOCH};
use template::render_centl_work_area;

#[cfg(unix)]
use std::os::fd::{AsRawFd, FromRawFd};
#[cfg(unix)]
use std::os::raw::{c_char, c_int};
#[cfg(unix)]
use std::os::unix::ffi::OsStrExt;
#[cfg(unix)]
use std::os::unix::fs::{MetadataExt, OpenOptionsExt, PermissionsExt};

#[cfg(unix)]
unsafe extern "C" {
    fn flock(file_descriptor: i32, operation: i32) -> i32;
    fn geteuid() -> u32;
    fn mkdirat(directory_fd: c_int, path: *const c_char, mode: u32) -> c_int;
    fn openat(directory_fd: c_int, path: *const c_char, flags: c_int, ...) -> c_int;
}

#[cfg(unix)]
const LOCK_EXCLUSIVE: i32 = 2;
#[cfg(unix)]
const LOCK_NONBLOCKING: i32 = 4;

#[cfg(any(target_os = "linux", target_os = "android"))]
const OPEN_DIRECTORY: c_int = 0o200000;
#[cfg(any(target_os = "linux", target_os = "android"))]
const OPEN_NOFOLLOW: c_int = 0o400000;
#[cfg(any(target_os = "linux", target_os = "android"))]
const OPEN_CLOEXEC: c_int = 0o2000000;

#[cfg(any(target_os = "macos", target_os = "ios"))]
const OPEN_DIRECTORY: c_int = 0x0010_0000;
#[cfg(any(target_os = "macos", target_os = "ios"))]
const OPEN_NOFOLLOW: c_int = 0x0000_0100;
#[cfg(any(target_os = "macos", target_os = "ios"))]
const OPEN_CLOEXEC: c_int = 0x0100_0000;

const MAX_LAB_HISTORY_ENTRIES: usize = 100;
const MAX_LAB_PROJECT_BYTES: usize = 8 * 1024 * 1024;
const LAB_PROJECT_SCHEMA: &str = "centl.project/1";
const LAB_PROJECT_FILE: &str = "project.centllab";
const LAB_PROJECT_LOCK_FILE: &str = ".centl26-project.lock";

const MAX_HEADER_BYTES: usize = 16 * 1024;
const MAX_BODY_BYTES: usize = 32 * 1024;
const MAX_HISTORY_ENTRIES: usize = 4;
const MAX_SESSIONS: usize = 1024;
const MAX_FLASHES: usize = 2048;
const SESSION_TTL: Duration = Duration::from_secs(2 * 60 * 60);
const FLASH_TTL: Duration = Duration::from_secs(60);
const SESSION_COOKIE: &str = "centl_sid";
const LAB_SESSION_COOKIE: &str = "centl26_sid";

#[derive(Debug)]
struct HttpRequest {
    method: String,
    target: String,
    headers: HashMap<String, String>,
    body: Vec<u8>,
}

struct SessionRecord {
    state: Arc<Mutex<AppState>>,
    last_seen: Instant,
}

struct LabProject {
    session_id: String,
    state: Arc<Mutex<AppState>>,
    store: Mutex<ProjectStore>,
}

#[derive(Debug)]
struct ProjectStore {
    root: PathBuf,
    revision: u64,
    _process_lock: ProjectProcessLock,
}

#[derive(Debug)]
struct ProjectProcessLock {
    _file: File,
}

struct FlashRecord {
    session_id: String,
    work_area_html: String,
    created: Instant,
}

struct ServerState {
    sessions: Mutex<HashMap<String, SessionRecord>>,
    flashes: Mutex<HashMap<String, FlashRecord>>,
    next_token: AtomicU64,
    lab_project: Option<LabProject>,
}

fn require_nofollow(options: &mut OpenOptions) {
    #[cfg(any(
        target_os = "linux",
        target_os = "android",
        target_os = "macos",
        target_os = "ios"
    ))]
    {
        options.custom_flags(OPEN_NOFOLLOW | OPEN_CLOEXEC);
    }
    #[cfg(not(any(
        target_os = "linux",
        target_os = "android",
        target_os = "macos",
        target_os = "ios"
    )))]
    let _ = options;
}

impl ServerState {
    fn new() -> Self {
        Self {
            sessions: Mutex::new(HashMap::new()),
            flashes: Mutex::new(HashMap::new()),
            next_token: AtomicU64::new(1),
            lab_project: None,
        }
    }

    fn new_lab() -> io::Result<Self> {
        Self::new_lab_at(default_lab_state_dir()?)
    }

    fn new_lab_at(root: PathBuf) -> io::Result<Self> {
        let (store, session) = ProjectStore::open(root)?;
        let mut server = Self::new();
        let session_id = server.new_secure_token()?;
        server.lab_project = Some(LabProject {
            session_id,
            state: Arc::new(Mutex::new(AppState { session })),
            store: Mutex::new(store),
        });
        Ok(server)
    }

    fn session_for(&self, requested_id: Option<&str>) -> (String, Arc<Mutex<AppState>>, bool) {
        if let Some(project) = &self.lab_project {
            let recognized = requested_id.is_some_and(|id| id == project.session_id);
            return (
                project.session_id.clone(),
                Arc::clone(&project.state),
                !recognized,
            );
        }

        let now = Instant::now();
        let mut sessions = self
            .sessions
            .lock()
            .unwrap_or_else(|poisoned| poisoned.into_inner());
        sessions.retain(|_, record| now.duration_since(record.last_seen) < SESSION_TTL);

        if let Some(id) = requested_id.filter(|id| valid_token(id)) {
            if let Some(record) = sessions.get_mut(id) {
                record.last_seen = now;
                return (id.to_string(), Arc::clone(&record.state), false);
            }
        }

        if sessions.len() >= MAX_SESSIONS {
            if let Some(oldest) = sessions
                .iter()
                .min_by_key(|(_, record)| record.last_seen)
                .map(|(id, _)| id.clone())
            {
                sessions.remove(&oldest);
            }
        }

        let id = self.new_token();
        let state = Arc::new(Mutex::new(AppState {
            session: Session::new(),
        }));
        sessions.insert(
            id.clone(),
            SessionRecord {
                state: Arc::clone(&state),
                last_seen: now,
            },
        );
        (id, state, true)
    }

    fn store_flash(&self, session_id: &str, work_area_html: String) -> String {
        let now = Instant::now();
        let mut flashes = self
            .flashes
            .lock()
            .unwrap_or_else(|poisoned| poisoned.into_inner());
        flashes.retain(|_, record| now.duration_since(record.created) < FLASH_TTL);
        if flashes.len() >= MAX_FLASHES {
            if let Some(oldest) = flashes
                .iter()
                .min_by_key(|(_, record)| record.created)
                .map(|(token, _)| token.clone())
            {
                flashes.remove(&oldest);
            }
        }
        let token = self.new_token();
        flashes.insert(
            token.clone(),
            FlashRecord {
                session_id: session_id.to_string(),
                work_area_html,
                created: now,
            },
        );
        token
    }

    fn take_flash(&self, token: &str, session_id: &str) -> Option<String> {
        if !valid_token(token) {
            return None;
        }
        let now = Instant::now();
        let mut flashes = self
            .flashes
            .lock()
            .unwrap_or_else(|poisoned| poisoned.into_inner());
        flashes.retain(|_, record| now.duration_since(record.created) < FLASH_TTL);
        let record = flashes.remove(token)?;
        (record.session_id == session_id).then_some(record.work_area_html)
    }

    fn new_token(&self) -> String {
        let mut bytes = [0u8; 16];
        if File::open("/dev/urandom")
            .and_then(|mut file| file.read_exact(&mut bytes))
            .is_err()
        {
            let counter = self.next_token.fetch_add(1, Ordering::Relaxed) as u128;
            let nanos = SystemTime::now()
                .duration_since(UNIX_EPOCH)
                .unwrap_or_default()
                .as_nanos();
            let mixed = nanos ^ counter.rotate_left(37) ^ ((std::process::id() as u128) << 64);
            bytes.copy_from_slice(&mixed.to_be_bytes());
        }
        bytes.iter().map(|byte| format!("{byte:02x}")).collect()
    }

    fn new_secure_token(&self) -> io::Result<String> {
        let mut bytes = [0u8; 16];
        File::open("/dev/urandom")?.read_exact(&mut bytes)?;
        Ok(bytes.iter().map(|byte| format!("{byte:02x}")).collect())
    }

    fn persist_lab_project(&self, state: &AppState) -> io::Result<()> {
        let Some(project) = &self.lab_project else {
            return Ok(());
        };
        project
            .store
            .lock()
            .unwrap_or_else(|poisoned| poisoned.into_inner())
            .save(&state.session)
    }

    fn authorizes_lab_session(&self, requested_id: Option<&str>) -> bool {
        self.lab_project
            .as_ref()
            .is_some_and(|project| requested_id == Some(project.session_id.as_str()))
    }
}

impl ProjectStore {
    fn open(root: PathBuf) -> io::Result<(Self, Session)> {
        validate_project_root(&root)?;
        let process_lock = ProjectProcessLock::acquire(&root)?;
        let path = root.join(LAB_PROJECT_FILE);
        if !path.exists() {
            return Ok((
                Self {
                    root,
                    revision: 0,
                    _process_lock: process_lock,
                },
                Session::new(),
            ));
        }

        let metadata = fs::symlink_metadata(&path)?;
        if metadata.file_type().is_symlink() || !metadata.is_file() {
            return Err(io::Error::new(
                io::ErrorKind::InvalidData,
                format!("CentL26 project is not a regular file: {}", path.display()),
            ));
        }
        if metadata.len() > MAX_LAB_PROJECT_BYTES as u64 {
            return Err(io::Error::new(
                io::ErrorKind::InvalidData,
                format!(
                    "CentL26 project exceeds the {} byte safety limit",
                    MAX_LAB_PROJECT_BYTES
                ),
            ));
        }

        let mut bytes = Vec::with_capacity(metadata.len() as usize);
        let mut options = OpenOptions::new();
        options.read(true);
        require_nofollow(&mut options);
        options
            .open(&path)?
            .take((MAX_LAB_PROJECT_BYTES + 1) as u64)
            .read_to_end(&mut bytes)?;
        if bytes.len() > MAX_LAB_PROJECT_BYTES {
            return Err(io::Error::new(
                io::ErrorKind::InvalidData,
                "CentL26 project grew beyond its safety limit while being read",
            ));
        }

        let (revision, session) = parse_lab_project(&bytes)?;
        Ok((
            Self {
                root,
                revision,
                _process_lock: process_lock,
            },
            session,
        ))
    }

    fn save(&mut self, session: &Session) -> io::Result<()> {
        validate_project_root(&self.root)?;
        let path = self.root.join(LAB_PROJECT_FILE);
        if let Ok(metadata) = fs::symlink_metadata(&path) {
            if metadata.file_type().is_symlink() || !metadata.is_file() {
                return Err(io::Error::new(
                    io::ErrorKind::InvalidData,
                    format!(
                        "refusing to replace unsafe project path: {}",
                        path.display()
                    ),
                ));
            }
        }

        let revision = self.revision.checked_add(1).ok_or_else(|| {
            io::Error::new(
                io::ErrorKind::InvalidData,
                "CentL26 project revision overflow",
            )
        })?;
        let bytes = serialize_lab_project(session, revision)?;
        if bytes.len() > MAX_LAB_PROJECT_BYTES {
            return Err(io::Error::new(
                io::ErrorKind::InvalidData,
                format!(
                    "CentL26 project exceeds the {} byte safety limit",
                    MAX_LAB_PROJECT_BYTES
                ),
            ));
        }

        let nonce = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap_or_default()
            .as_nanos();
        let temporary = self.root.join(format!(
            ".{}.new-{}-{}-{}",
            LAB_PROJECT_FILE,
            std::process::id(),
            revision,
            nonce
        ));
        let mut options = OpenOptions::new();
        options.write(true).create_new(true);
        require_nofollow(&mut options);
        #[cfg(unix)]
        options.mode(0o600);

        let write_result = (|| -> io::Result<()> {
            let mut file = options.open(&temporary)?;
            file.write_all(&bytes)?;
            file.sync_all()?;
            fs::rename(&temporary, &path)?;
            #[cfg(unix)]
            {
                // The temporary file was created 0600. Renaming it is the
                // commit point; a directory fsync is best-effort because a
                // post-commit error must not roll back only the in-memory copy.
                let _ = File::open(&self.root).and_then(|directory| directory.sync_all());
            }
            Ok(())
        })();

        if write_result.is_err() {
            let _ = fs::remove_file(&temporary);
        }
        write_result?;
        self.revision = revision;
        Ok(())
    }
}

impl ProjectProcessLock {
    fn acquire(root: &Path) -> io::Result<Self> {
        #[cfg(not(unix))]
        {
            let _ = root;
            return Err(io::Error::new(
                io::ErrorKind::Unsupported,
                "CentL26 project locking is not implemented on this platform",
            ));
        }

        #[cfg(unix)]
        {
            let path = root.join(LAB_PROJECT_LOCK_FILE);
            let mut create_options = OpenOptions::new();
            create_options
                .read(true)
                .write(true)
                .create_new(true)
                .mode(0o600);
            require_nofollow(&mut create_options);
            let (file, created) = match create_options.open(&path) {
                Ok(file) => (file, true),
                Err(error) if error.kind() == io::ErrorKind::AlreadyExists => {
                    let mut open_options = OpenOptions::new();
                    open_options.read(true).write(true);
                    require_nofollow(&mut open_options);
                    let file = open_options.open(&path)?;
                    (file, false)
                }
                Err(error) => return Err(error),
            };

            let path_metadata = fs::symlink_metadata(&path)?;
            let file_metadata = file.metadata()?;
            let current_uid = unsafe { geteuid() };
            if path_metadata.file_type().is_symlink()
                || !path_metadata.is_file()
                || !file_metadata.is_file()
                || path_metadata.dev() != file_metadata.dev()
                || path_metadata.ino() != file_metadata.ino()
                || file_metadata.uid() != current_uid
                || file_metadata.mode() & 0o077 != 0
            {
                return Err(io::Error::new(
                    io::ErrorKind::PermissionDenied,
                    format!("unsafe CentL26 project lock: {}", path.display()),
                ));
            }
            if created && file_metadata.mode() & 0o777 != 0o600 {
                return Err(io::Error::new(
                    io::ErrorKind::PermissionDenied,
                    "new CentL26 project lock did not receive private permissions",
                ));
            }

            let result = unsafe { flock(file.as_raw_fd(), LOCK_EXCLUSIVE | LOCK_NONBLOCKING) };
            if result != 0 {
                let error = io::Error::last_os_error();
                return Err(io::Error::new(
                    io::ErrorKind::WouldBlock,
                    format!(
                        "CentL26 project is already open by another process ({}): {}",
                        path.display(),
                        error
                    ),
                ));
            }
            Ok(Self { _file: file })
        }
    }
}

fn default_lab_state_dir() -> io::Result<PathBuf> {
    if let Some(configured) = env::var_os("CENTL26_STATE_DIR").filter(|value| !value.is_empty()) {
        let path = PathBuf::from(configured);
        if !path.is_absolute() {
            return Err(io::Error::new(
                io::ErrorKind::InvalidInput,
                "CENTL26_STATE_DIR must be an absolute path",
            ));
        }
        return Ok(path);
    }

    let home = env::var_os("HOME")
        .filter(|value| !value.is_empty())
        .ok_or_else(|| {
            io::Error::new(
                io::ErrorKind::NotFound,
                "CentL26 needs HOME or an explicit CENTL26_STATE_DIR for project storage",
            )
        })?;
    Ok(PathBuf::from(home)
        .join(".centl")
        .join("workspaces")
        .join("default"))
}

fn validate_project_root(root: &Path) -> io::Result<()> {
    if !root.is_absolute() {
        return Err(io::Error::new(
            io::ErrorKind::InvalidInput,
            "CentL26 project root must be absolute",
        ));
    }
    if root
        .components()
        .any(|component| !matches!(component, Component::RootDir | Component::Normal(_)))
    {
        return Err(io::Error::new(
            io::ErrorKind::InvalidInput,
            "CentL26 project root may not contain relative path components",
        ));
    }

    let normal_components = root
        .components()
        .filter(|component| matches!(component, Component::Normal(_)))
        .count();
    let broad_system_root = [
        "/",
        "/Applications",
        "/Library",
        "/System",
        "/Users",
        "/bin",
        "/etc",
        "/home",
        "/private",
        "/private/tmp",
        "/private/var",
        "/sbin",
        "/tmp",
        "/usr",
        "/var",
    ]
    .iter()
    .any(|candidate| root == Path::new(candidate));
    let shared_temporary_tree = ["/tmp", "/private/tmp", "/var/tmp", "/private/var/tmp"]
        .iter()
        .any(|candidate| root.starts_with(candidate));
    if normal_components < 2 || broad_system_root || shared_temporary_tree {
        return Err(io::Error::new(
            io::ErrorKind::PermissionDenied,
            format!(
                "CentL26 project root must be a dedicated application directory: {}",
                root.display()
            ),
        ));
    }

    if let Some(home) = env::var_os("HOME").filter(|value| !value.is_empty()) {
        let home = PathBuf::from(home);
        if root == home
            || root
                .strip_prefix(&home)
                .ok()
                .is_some_and(|relative| relative.components().count() < 2)
        {
            return Err(io::Error::new(
                io::ErrorKind::PermissionDenied,
                format!(
                    "CentL26 project root is too broad within the home directory: {}",
                    root.display()
                ),
            ));
        }
    }

    ensure_project_root_no_follow(root)
}

#[cfg(any(
    target_os = "linux",
    target_os = "android",
    target_os = "macos",
    target_os = "ios"
))]
fn ensure_project_root_no_follow(root: &Path) -> io::Result<()> {
    let mut parent = File::open("/")?;
    let components = root
        .components()
        .filter_map(|component| match component {
            Component::Normal(name) => Some(name),
            _ => None,
        })
        .collect::<Vec<_>>();

    for (index, name) in components.iter().enumerate() {
        let encoded = CString::new(name.as_bytes()).map_err(|_| {
            io::Error::new(
                io::ErrorKind::InvalidInput,
                "CentL26 project path contains an invalid null byte",
            )
        })?;
        let mut created = false;
        let mut descriptor = unsafe {
            openat(
                parent.as_raw_fd(),
                encoded.as_ptr(),
                OPEN_DIRECTORY | OPEN_NOFOLLOW | OPEN_CLOEXEC,
            )
        };
        if descriptor < 0 {
            let open_error = io::Error::last_os_error();
            if open_error.kind() != io::ErrorKind::NotFound {
                return Err(io::Error::new(
                    io::ErrorKind::PermissionDenied,
                    format!(
                        "CentL26 could not open a project directory without following links ({}): {}",
                        root.display(),
                        open_error
                    ),
                ));
            }

            let creation_result = unsafe { mkdirat(parent.as_raw_fd(), encoded.as_ptr(), 0o700) };
            if creation_result == 0 {
                created = true;
            } else {
                let creation_error = io::Error::last_os_error();
                if creation_error.kind() != io::ErrorKind::AlreadyExists {
                    return Err(creation_error);
                }
            }
            descriptor = unsafe {
                openat(
                    parent.as_raw_fd(),
                    encoded.as_ptr(),
                    OPEN_DIRECTORY | OPEN_NOFOLLOW | OPEN_CLOEXEC,
                )
            };
            if descriptor < 0 {
                let error = io::Error::last_os_error();
                return Err(io::Error::new(
                    io::ErrorKind::PermissionDenied,
                    format!(
                        "CentL26 rejected a project path component created concurrently ({}): {}",
                        root.display(),
                        error
                    ),
                ));
            }
        }

        let child = unsafe { File::from_raw_fd(descriptor) };
        if created {
            child.set_permissions(fs::Permissions::from_mode(0o700))?;
        }
        let metadata = child.metadata()?;
        if !metadata.is_dir() || metadata.mode() & 0o022 != 0 {
            return Err(io::Error::new(
                io::ErrorKind::PermissionDenied,
                format!(
                    "CentL26 project paths may not traverse directories writable by other accounts: {}",
                    root.display()
                ),
            ));
        }
        if index + 1 == components.len() && metadata.uid() != unsafe { geteuid() } {
            return Err(io::Error::new(
                io::ErrorKind::PermissionDenied,
                format!(
                    "CentL26 project root must be owned by the current user: {}",
                    root.display()
                ),
            ));
        }
        parent = child;
    }
    Ok(())
}

#[cfg(not(any(
    target_os = "linux",
    target_os = "android",
    target_os = "macos",
    target_os = "ios"
)))]
fn ensure_project_root_no_follow(_root: &Path) -> io::Result<()> {
    Err(io::Error::new(
        io::ErrorKind::Unsupported,
        "CentL26 secure project storage is not implemented on this platform",
    ))
}

fn serialize_lab_project(session: &Session, revision: u64) -> io::Result<Vec<u8>> {
    if session.history.len() > MAX_LAB_HISTORY_ENTRIES {
        return Err(io::Error::new(
            io::ErrorKind::InvalidData,
            "CentL26 notebook contains too many run records",
        ));
    }

    let runs: Vec<serde_json::Value> = session
        .history
        .iter()
        .map(|entry| {
            serde_json::json!({
                "command": entry.command,
                "result": entry.result,
                "exact": entry.exact_repr,
                "approximate": entry.approximate_repr,
                "execution_micros": entry.execution_micros.to_string(),
                "success": entry.success,
            })
        })
        .collect();
    let document = serde_json::json!({
        "schema": LAB_PROJECT_SCHEMA,
        "product": "CentL26",
        "revision": revision,
        "notebook": {
            "id": "notebook-01",
            "runs": runs,
        }
    });
    serde_json::to_vec_pretty(&document).map_err(|error| {
        io::Error::new(
            io::ErrorKind::InvalidData,
            format!("could not encode CentL26 project: {error}"),
        )
    })
}

fn parse_lab_project(bytes: &[u8]) -> io::Result<(u64, Session)> {
    let document: serde_json::Value = serde_json::from_slice(bytes).map_err(|error| {
        io::Error::new(
            io::ErrorKind::InvalidData,
            format!("CentL26 project is not valid JSON: {error}"),
        )
    })?;
    let root = document.as_object().ok_or_else(|| {
        io::Error::new(
            io::ErrorKind::InvalidData,
            "CentL26 project root must be an object",
        )
    })?;
    if root.get("schema").and_then(|value| value.as_str()) != Some(LAB_PROJECT_SCHEMA) {
        return Err(io::Error::new(
            io::ErrorKind::InvalidData,
            format!(
                "unsupported CentL26 project schema; expected {}",
                LAB_PROJECT_SCHEMA
            ),
        ));
    }
    let revision = root
        .get("revision")
        .and_then(|value| value.as_u64())
        .ok_or_else(|| {
            io::Error::new(
                io::ErrorKind::InvalidData,
                "invalid CentL26 project revision",
            )
        })?;
    let notebook = root
        .get("notebook")
        .and_then(|value| value.as_object())
        .ok_or_else(|| {
            io::Error::new(
                io::ErrorKind::InvalidData,
                "CentL26 project notebook is missing",
            )
        })?;
    if notebook.get("id").and_then(|value| value.as_str()) != Some("notebook-01") {
        return Err(io::Error::new(
            io::ErrorKind::InvalidData,
            "unsupported CentL26 notebook identity",
        ));
    }
    let runs = notebook
        .get("runs")
        .and_then(|value| value.as_array())
        .ok_or_else(|| {
            io::Error::new(
                io::ErrorKind::InvalidData,
                "CentL26 notebook runs are missing",
            )
        })?;
    if runs.len() > MAX_LAB_HISTORY_ENTRIES {
        return Err(io::Error::new(
            io::ErrorKind::InvalidData,
            "CentL26 project contains too many run records",
        ));
    }

    let mut session = Session::new();
    for run in runs {
        session.history.push(parse_project_run(run)?);
    }
    Ok((revision, session))
}

fn parse_project_run(value: &serde_json::Value) -> io::Result<HistoryEntry> {
    let run = value.as_object().ok_or_else(|| {
        io::Error::new(io::ErrorKind::InvalidData, "notebook run must be an object")
    })?;
    Ok(HistoryEntry {
        command: required_project_string(run, "command")?.to_string(),
        result: required_project_string(run, "result")?.to_string(),
        exact_repr: optional_project_string(run, "exact")?,
        approximate_repr: optional_project_string(run, "approximate")?,
        execution_micros: required_project_string(run, "execution_micros")?
            .parse::<u128>()
            .map_err(|_| io::Error::new(io::ErrorKind::InvalidData, "invalid run duration"))?,
        success: run
            .get("success")
            .and_then(|value| value.as_bool())
            .ok_or_else(|| {
                io::Error::new(io::ErrorKind::InvalidData, "invalid run success state")
            })?,
    })
}

fn required_project_string<'a>(
    object: &'a serde_json::Map<String, serde_json::Value>,
    field: &str,
) -> io::Result<&'a str> {
    object
        .get(field)
        .and_then(|value| value.as_str())
        .ok_or_else(|| {
            io::Error::new(
                io::ErrorKind::InvalidData,
                format!("notebook run field is missing or invalid: {field}"),
            )
        })
}

fn optional_project_string(
    object: &serde_json::Map<String, serde_json::Value>,
    field: &str,
) -> io::Result<Option<String>> {
    let Some(value) = object.get(field) else {
        return Err(io::Error::new(
            io::ErrorKind::InvalidData,
            format!("notebook run field is missing: {field}"),
        ));
    };
    if value.is_null() {
        return Ok(None);
    }
    value
        .as_str()
        .map(|value| Some(value.to_string()))
        .ok_or_else(|| {
            io::Error::new(
                io::ErrorKind::InvalidData,
                format!("notebook run field must be text or null: {field}"),
            )
        })
}

pub fn start_server(port: u16, site_dir: &str) -> io::Result<()> {
    let bind_host = env::var("CENTL_BIND_HOST").unwrap_or_else(|_| "127.0.0.1".to_string());
    let addr = format!("{}:{}", bind_host, port);
    let listener = TcpListener::bind(&addr)?;
    println!("============================================================");
    println!(
        "CENTL Hub & Zero-JS Web Application running at http://{}",
        addr
    );
    println!("Serving static files from: {}", site_dir);
    println!("Build commit: {}", build_commit());
    println!("No JavaScript required. Exact mathematics & Erdős–Straus hunt active.");
    println!("============================================================");

    let state = Arc::new(ServerState::new());
    let site_path = Arc::new(site_dir.to_string());

    for stream in listener.incoming() {
        match stream {
            Ok(stream) => {
                let state_clone = Arc::clone(&state);
                let site_clone = Arc::clone(&site_path);
                thread::spawn(move || {
                    if let Err(error) = handle_connection(stream, state_clone, &site_clone) {
                        eprintln!("CENTL web request failed: {}", error);
                    }
                });
            }
            Err(error) => eprintln!("Connection error: {}", error),
        }
    }
    Ok(())
}

/// Start the standalone CentL26 application host.
///
/// Unlike `start_server`, this host does not serve the public FCF site and does
/// not read a site directory. Its application assets are embedded in the
/// binary and it binds to loopback only so the scientific workspace remains a
/// private, offline-first local process.
pub fn start_lab_server(port: u16) -> io::Result<()> {
    let state = Arc::new(ServerState::new_lab()?);
    let addr = format!("127.0.0.1:{}", port);
    let listener = TcpListener::bind(&addr)?;
    println!("CentL26 running at http://{}", addr);
    println!("Private loopback host · embedded assets · no network dependency");
    println!("Press Ctrl-C to stop CentL26.");

    for stream in listener.incoming() {
        match stream {
            Ok(stream) => {
                let state_clone = Arc::clone(&state);
                thread::spawn(move || {
                    if let Err(error) = handle_lab_connection(stream, state_clone) {
                        eprintln!("CentL26 request failed: {}", error);
                    }
                });
            }
            Err(error) => eprintln!("CentL26 connection error: {}", error),
        }
    }
    Ok(())
}

fn handle_lab_connection(mut stream: TcpStream, server_state: Arc<ServerState>) -> io::Result<()> {
    stream.set_read_timeout(Some(Duration::from_secs(8)))?;
    stream.set_write_timeout(Some(Duration::from_secs(15)))?;

    let request = match read_http_request(&mut stream) {
        Ok(Some(request)) => request,
        Ok(None) => return Ok(()),
        Err(error) => {
            return write_text_response(
                &mut stream,
                400,
                "Bad Request",
                &format!("Bad request: {}", error),
                &[],
                false,
            )
        }
    };

    let method = request.method.as_str();
    let path = request.target.split('?').next().unwrap_or("/");
    let is_head = method == "HEAD";
    let expected_authority = stream.local_addr()?.to_string();

    if !lab_host_is_authorized(&request, &expected_authority) {
        return write_text_response(
            &mut stream,
            403,
            "Forbidden",
            "CentL26 rejected an untrusted local origin.\n",
            &[("Cache-Control", "no-store".to_string())],
            is_head,
        );
    }

    if (method == "GET" || is_head) && path == "/lab.css" {
        return write_response(
            &mut stream,
            200,
            "OK",
            "text/css; charset=utf-8",
            lab_template::LAB_CSS.as_bytes(),
            &[("Cache-Control", "no-store".to_string())],
            is_head,
        );
    }
    if (method == "GET" || is_head) && path == "/lab.js" {
        return write_response(
            &mut stream,
            200,
            "OK",
            "text/javascript; charset=utf-8",
            lab_template::LAB_JS.as_bytes(),
            &[("Cache-Control", "no-store".to_string())],
            is_head,
        );
    }
    if (method == "GET" || is_head) && path == "/api/capabilities" {
        return write_response(
            &mut stream,
            200,
            "OK",
            "application/json; charset=utf-8",
            lab_template::CAPABILITY_REGISTRY.as_bytes(),
            &[("Cache-Control", "no-store".to_string())],
            is_head,
        );
    }
    if (method == "GET" || is_head) && (path == "/__centl26" || path == "/__centl_lab") {
        return write_text_response(
            &mut stream,
            200,
            "OK",
            &format!("centl26 {}\n", build_commit()),
            &[("Cache-Control", "no-store".to_string())],
            is_head,
        );
    }

    let is_page = path == "/" || path == "/index.html" || path == "/run";
    let is_api_run = path == "/api/run";
    if !is_page && !is_api_run {
        return write_text_response(
            &mut stream,
            404,
            "Not Found",
            "CentL26 route not found\n",
            &[],
            is_head,
        );
    }
    if method != "GET" && method != "HEAD" && method != "POST" {
        return write_text_response(
            &mut stream,
            405,
            "Method Not Allowed",
            "Method not allowed",
            &[("Allow", "GET, HEAD, POST".to_string())],
            is_head,
        );
    }

    let requested_session = request
        .headers
        .get("cookie")
        .and_then(|header| cookie_value(header, LAB_SESSION_COOKIE));
    if method == "POST"
        && !lab_mutation_is_authorized(
            &request,
            &server_state,
            &expected_authority,
            requested_session.as_deref(),
        )
    {
        return write_text_response(
            &mut stream,
            403,
            "Forbidden",
            "CentL26 rejected an unauthenticated workspace mutation.\n",
            &[("Cache-Control", "no-store".to_string())],
            is_head,
        );
    }
    let (session_id, session_state, is_new_session) =
        server_state.session_for(requested_session.as_deref());

    let (workbench, input_value) = if method == "POST" {
        let body = String::from_utf8_lossy(&request.body);
        let command = lab_command_from_body(&body);
        let mut app_state = session_state
            .lock()
            .unwrap_or_else(|poisoned| poisoned.into_inner());
        let previous_session = app_state.session.clone();
        let (mut last_result, mut last_error, mut last_physics, mut last_hunt) =
            handle_command(&command, &mut app_state);
        trim_lab_history(&mut app_state);
        if last_error.is_none() && !command.trim().is_empty() {
            if let Err(error) = server_state.persist_lab_project(&app_state) {
                app_state.session = previous_session;
                last_result = None;
                last_physics = None;
                last_hunt = None;
                last_error = Some(format!(
                    "Project autosave failed; no work was admitted: {}",
                    error
                ));
            }
        }
        let input_value = if last_error.is_some() {
            command.clone()
        } else {
            String::new()
        };
        let mut display_session = None;
        if last_physics.is_some() || last_hunt.is_some() {
            let mut without_specialized_card_duplicate = app_state.session.clone();
            without_specialized_card_duplicate.history.pop();
            display_session = Some(without_specialized_card_duplicate);
        }
        let session_for_render = display_session.as_ref().unwrap_or(&app_state.session);
        (
            lab_template::render_lab_workbench(
                &input_value,
                last_result.as_ref(),
                last_error.as_deref(),
                last_physics.as_ref(),
                last_hunt.as_ref(),
                session_for_render,
            ),
            input_value,
        )
    } else {
        let app_state = session_state
            .lock()
            .unwrap_or_else(|poisoned| poisoned.into_inner());
        (
            lab_template::render_lab_workbench("", None, None, None, None, &app_state.session),
            String::new(),
        )
    };
    let _ = input_value;

    let mut headers = vec![
        ("Cache-Control", "no-store, private, max-age=0".to_string()),
        ("X-Content-Type-Options", "nosniff".to_string()),
        ("Content-Security-Policy", "default-src 'self'; style-src 'self'; script-src 'self'; img-src 'self' data:; connect-src 'self'; object-src 'none'; base-uri 'none'; frame-ancestors 'none'".to_string()),
    ];
    if is_new_session {
        headers.push(("Set-Cookie", lab_session_cookie_header(&session_id)));
    }

    if is_api_run {
        write_html_response(&mut stream, 200, "OK", &workbench, &headers, is_head)
    } else {
        let full_page = lab_template::render_lab_page(&workbench);
        write_html_response(&mut stream, 200, "OK", &full_page, &headers, is_head)
    }
}

fn lab_command_from_body(body: &str) -> String {
    match extract_form_value(body, "lab_action").as_str() {
        "approximate" => {
            let expression = extract_form_value(body, "expression");
            let digits = extract_form_value(body, "digits");
            format!("approx({}, {})", expression.trim(), digits.trim())
        }
        "convert" => format!(
            "physics convert {} {} {}",
            extract_form_value(body, "value").trim(),
            extract_form_value(body, "from_unit").trim(),
            extract_form_value(body, "to_unit").trim()
        ),
        "collision" => format!(
            "physics collision m1={} v1={} m2={} v2={} e={}",
            extract_form_value(body, "m1").trim(),
            extract_form_value(body, "v1").trim(),
            extract_form_value(body, "m2").trim(),
            extract_form_value(body, "v2").trim(),
            extract_form_value(body, "restitution").trim()
        ),
        "es_solve" => format!("es solve {}", extract_form_value(body, "prime").trim()),
        "es_hunt" => format!("es hunt {}", extract_form_value(body, "from").trim()),
        _ => extract_form_value(body, "cmd"),
    }
}

fn trim_lab_history(state: &mut AppState) {
    let len = state.session.history.len();
    if len > MAX_LAB_HISTORY_ENTRIES {
        state.session.history.drain(..len - MAX_LAB_HISTORY_ENTRIES);
    }
}

fn handle_connection(
    mut stream: TcpStream,
    server_state: Arc<ServerState>,
    site_dir: &str,
) -> io::Result<()> {
    stream.set_read_timeout(Some(Duration::from_secs(8)))?;
    stream.set_write_timeout(Some(Duration::from_secs(15)))?;

    let request = match read_http_request(&mut stream) {
        Ok(Some(request)) => request,
        Ok(None) => return Ok(()),
        Err(error) => {
            let body = format!("Bad request: {}", error);
            return write_text_response(&mut stream, 400, "Bad Request", &body, &[], false);
        }
    };

    let method = request.method.as_str();
    let raw_path = request.target.as_str();
    let path = raw_path.split('?').next().unwrap_or("/");
    let is_head = method == "HEAD";

    if (method == "GET" || is_head) && path == "/__centl_origin" {
        let body = format!("centl-web {}\n", build_commit());
        return write_text_response(
            &mut stream,
            200,
            "OK",
            &body,
            &[("Cache-Control", "no-store".to_string())],
            is_head,
        );
    }

    if method == "POST" && (path == "/" || path == "/index.html") {
        return write_redirect(&mut stream, 307, "Temporary Redirect", "/hub");
    }

    if (method == "GET" || is_head) && (path == "/" || path == "/index.html") {
        return serve_static_file(&mut stream, site_dir, "index.html", is_head);
    }

    if path == "/hub" || path == "/hub.html" {
        if method != "GET" && method != "HEAD" && method != "POST" {
            return write_text_response(
                &mut stream,
                405,
                "Method Not Allowed",
                "Method not allowed",
                &[("Allow", "GET, HEAD, POST".to_string())],
                is_head,
            );
        }

        let requested_session = request
            .headers
            .get("cookie")
            .and_then(|header| cookie_value(header, SESSION_COOKIE));
        let (session_id, session_state, is_new_session) =
            server_state.session_for(requested_session.as_deref());

        if method == "POST" {
            let body = String::from_utf8_lossy(&request.body);
            let post_cmd = extract_form_value(&body, "cmd");
            let work_area = {
                let mut app_state = session_state
                    .lock()
                    .unwrap_or_else(|poisoned| poisoned.into_inner());
                let (last_result, last_error, last_physics, last_hunt) =
                    handle_command(&post_cmd, &mut app_state);
                trim_history(&mut app_state);
                let input_value = if last_error.is_some() {
                    post_cmd.as_str()
                } else {
                    ""
                };
                render_centl_work_area(
                    input_value,
                    last_result.as_ref(),
                    last_error.as_deref(),
                    last_physics.as_ref(),
                    last_hunt.as_ref(),
                    &app_state.session,
                    "/hub",
                )
            };

            let view_token = server_state.store_flash(&session_id, work_area);
            let location = format!("/hub?view={}#centl-console", view_token);
            let mut headers = Vec::new();
            if is_new_session {
                headers.push((
                    "Set-Cookie",
                    session_cookie_header(&session_id, request_is_https(&request)),
                ));
            }
            return write_redirect_with_headers(&mut stream, 303, "See Other", &location, &headers);
        }

        let work_area = if is_head {
            render_pristine_work_area()
        } else {
            let view_token = raw_path
                .find('?')
                .map(|index| extract_form_value(&raw_path[index + 1..], "view"))
                .unwrap_or_default();
            if !view_token.is_empty() {
                server_state.take_flash(&view_token, &session_id)
            } else {
                None
            }
            .unwrap_or_else(|| {
                let mut app_state = session_state
                    .lock()
                    .unwrap_or_else(|poisoned| poisoned.into_inner());
                reset_session(&mut app_state);
                render_centl_work_area("", None, None, None, None, &app_state.session, "/hub")
            })
        };

        let full_html = render_hub_page(&work_area);
        let mut headers = vec![
            ("Cache-Control", "no-store, private, max-age=0".to_string()),
            ("Pragma", "no-cache".to_string()),
            ("Expires", "0".to_string()),
            ("X-Content-Type-Options", "nosniff".to_string()),
            ("Referrer-Policy", "same-origin".to_string()),
        ];
        if is_new_session {
            headers.push((
                "Set-Cookie",
                session_cookie_header(&session_id, request_is_https(&request)),
            ));
        }
        return write_html_response(&mut stream, 200, "OK", &full_html, &headers, is_head);
    }

    if method != "GET" && !is_head {
        return write_text_response(
            &mut stream,
            405,
            "Method Not Allowed",
            "Method not allowed",
            &[("Allow", "GET, HEAD".to_string())],
            is_head,
        );
    }

    let clean_path = path.trim_start_matches('/');
    if safe_relative_path(clean_path).is_none() {
        return write_text_response(&mut stream, 403, "Forbidden", "Forbidden", &[], is_head);
    }

    let target_file = Path::new(site_dir).join(clean_path);
    if target_file.is_file() {
        return serve_file_path(&mut stream, &target_file, is_head);
    }

    write_text_response(
        &mut stream,
        404,
        "Not Found",
        "404 Not Found\n",
        &[],
        is_head,
    )
}

fn render_pristine_work_area() -> String {
    let session = Session::new();
    render_centl_work_area("", None, None, None, None, &session, "/hub")
}

fn render_hub_page(work_area: &str) -> String {
    let home_sections = r#"
        <div class="hub-pathways">
          <section class="hub-card">
            <h3>Exact Scientific & Mathematics Hub</h3>
            <p>CENTL computes exact integers, fractions, and symbolic calculus directly. No unqualified approximations.</p>
            <p class="card-links"><a href="centl.html">About CENTL</a> · <a href="manuals/numerics.html">Numerical Contract</a></p>
          </section>
          <section class="hub-card">
            <h3>Erdős–Straus Program & Public Hunt</h3>
            <p>Join the public hunt for 3-Egyptian fraction decompositions, certificates, and content-addressed findings.</p>
            <p class="card-links"><a href="research-erdos-straus.html">Research Program</a> · <a href="research-erdos-straus.html#es-hunt">Public Hunt</a></p>
          </section>
          <section class="hub-card">
            <h3>Field Manuals & Onboarding</h3>
            <p>Dedicated guides for mathematicians, physicists, developers, and researchers.</p>
            <p class="card-links"><a href="docs.html">Documentation Portal</a> · <a href="manuals/install.html">Installation</a></p>
          </section>
          <section class="hub-card">
            <h3>Preservation & The Bazaar</h3>
            <p>Open science, mirror archives, and public funding sponsorship for serious computation.</p>
            <p class="card-links"><a href="about.html">About FCF</a> · <a href="funding.html">Funding</a> · <a href="mirrors.html">The Bazaar</a></p>
          </section>
        </div>
        "#;
    let full_content = format!("{}\n{}", work_area, home_sections);
    render_full_page(&full_content, "CENTL Work Area", "")
}

fn read_http_request(stream: &mut TcpStream) -> io::Result<Option<HttpRequest>> {
    let mut data = Vec::with_capacity(4096);
    let mut scratch = [0u8; 4096];
    let header_end = loop {
        let read = stream.read(&mut scratch)?;
        if read == 0 {
            if data.is_empty() {
                return Ok(None);
            }
            return Err(io::Error::new(
                io::ErrorKind::UnexpectedEof,
                "connection closed before request headers completed",
            ));
        }
        data.extend_from_slice(&scratch[..read]);
        if let Some(index) = find_bytes(&data, b"\r\n\r\n") {
            break index + 4;
        }
        if data.len() > MAX_HEADER_BYTES {
            return Err(io::Error::new(
                io::ErrorKind::InvalidData,
                "request headers exceed limit",
            ));
        }
    };

    if header_end > MAX_HEADER_BYTES {
        return Err(io::Error::new(
            io::ErrorKind::InvalidData,
            "request headers exceed limit",
        ));
    }

    let header_text = std::str::from_utf8(&data[..header_end]).map_err(|_| {
        io::Error::new(
            io::ErrorKind::InvalidData,
            "request headers are not valid UTF-8",
        )
    })?;
    let mut lines = header_text[..header_text.len() - 4].split("\r\n");
    let request_line = lines
        .next()
        .ok_or_else(|| io::Error::new(io::ErrorKind::InvalidData, "missing request line"))?;
    let mut request_parts = request_line.split_whitespace();
    let method = request_parts
        .next()
        .ok_or_else(|| io::Error::new(io::ErrorKind::InvalidData, "missing method"))?
        .to_string();
    let target = request_parts
        .next()
        .ok_or_else(|| io::Error::new(io::ErrorKind::InvalidData, "missing request target"))?
        .to_string();
    let version = request_parts
        .next()
        .ok_or_else(|| io::Error::new(io::ErrorKind::InvalidData, "missing HTTP version"))?;
    if !version.starts_with("HTTP/1.") {
        return Err(io::Error::new(
            io::ErrorKind::InvalidData,
            "unsupported HTTP version",
        ));
    }

    let mut headers = HashMap::new();
    for line in lines {
        let Some((name, value)) = line.split_once(':') else {
            return Err(io::Error::new(
                io::ErrorKind::InvalidData,
                "malformed request header",
            ));
        };
        headers.insert(name.trim().to_ascii_lowercase(), value.trim().to_string());
    }

    if headers
        .get("transfer-encoding")
        .is_some_and(|value| !value.eq_ignore_ascii_case("identity"))
    {
        return Err(io::Error::new(
            io::ErrorKind::InvalidData,
            "chunked request bodies are not supported",
        ));
    }

    let content_length = match headers.get("content-length") {
        Some(value) => value
            .parse::<usize>()
            .map_err(|_| io::Error::new(io::ErrorKind::InvalidData, "invalid Content-Length"))?,
        None => 0,
    };
    if content_length > MAX_BODY_BYTES {
        return Err(io::Error::new(
            io::ErrorKind::InvalidData,
            "request body exceeds limit",
        ));
    }

    let required = header_end + content_length;
    while data.len() < required {
        let read = stream.read(&mut scratch)?;
        if read == 0 {
            return Err(io::Error::new(
                io::ErrorKind::UnexpectedEof,
                "connection closed before request body completed",
            ));
        }
        data.extend_from_slice(&scratch[..read]);
        if data.len() > MAX_HEADER_BYTES + MAX_BODY_BYTES {
            return Err(io::Error::new(
                io::ErrorKind::InvalidData,
                "request exceeds limit",
            ));
        }
    }

    Ok(Some(HttpRequest {
        method,
        target,
        headers,
        body: data[header_end..required].to_vec(),
    }))
}

fn find_bytes(haystack: &[u8], needle: &[u8]) -> Option<usize> {
    haystack
        .windows(needle.len())
        .position(|window| window == needle)
}

fn trim_history(state: &mut AppState) {
    let len = state.session.history.len();
    if len > MAX_HISTORY_ENTRIES {
        state.session.history.drain(..len - MAX_HISTORY_ENTRIES);
    }
}

fn reset_session(state: &mut AppState) {
    state.session = Session::new();
}

fn lab_mutation_is_authorized(
    request: &HttpRequest,
    server_state: &ServerState,
    expected_authority: &str,
    requested_session: Option<&str>,
) -> bool {
    let expected_origin = format!("http://{}", expected_authority);
    request.headers.get("origin").map(String::as_str) == Some(expected_origin.as_str())
        && server_state.authorizes_lab_session(requested_session)
}

fn lab_host_is_authorized(request: &HttpRequest, expected_authority: &str) -> bool {
    request.headers.get("host").map(String::as_str) == Some(expected_authority)
}

fn cookie_value(cookie_header: &str, name: &str) -> Option<String> {
    cookie_header.split(';').find_map(|part| {
        let (key, value) = part.trim().split_once('=')?;
        (key == name).then(|| value.to_string())
    })
}

fn valid_token(id: &str) -> bool {
    id.len() == 32 && id.bytes().all(|byte| byte.is_ascii_hexdigit())
}

fn request_is_https(request: &HttpRequest) -> bool {
    request
        .headers
        .get("x-forwarded-proto")
        .is_some_and(|value| value.eq_ignore_ascii_case("https"))
}

fn session_cookie_header(session_id: &str, secure: bool) -> String {
    named_session_cookie_header(SESSION_COOKIE, session_id, secure)
}

fn lab_session_cookie_header(session_id: &str) -> String {
    format!(
        "{}={}; Path=/; HttpOnly; SameSite=Strict; Max-Age={}",
        LAB_SESSION_COOKIE,
        session_id,
        SESSION_TTL.as_secs(),
    )
}

fn named_session_cookie_header(name: &str, session_id: &str, secure: bool) -> String {
    let secure_attribute = if secure { "; Secure" } else { "" };
    format!(
        "{}={}; Path=/; HttpOnly; SameSite=Lax; Max-Age={}{}",
        name,
        session_id,
        SESSION_TTL.as_secs(),
        secure_attribute
    )
}

fn extract_form_value(body: &str, key: &str) -> String {
    for pair in body.split('&') {
        if let Some((raw_key, raw_value)) = pair.split_once('=') {
            if url_decode(raw_key) == key {
                return url_decode(raw_value);
            }
        }
    }
    String::new()
}

fn url_decode(value: &str) -> String {
    let bytes = value.as_bytes();
    let mut decoded = Vec::with_capacity(bytes.len());
    let mut index = 0;
    while index < bytes.len() {
        match bytes[index] {
            b'+' => {
                decoded.push(b' ');
                index += 1;
            }
            b'%' if index + 2 < bytes.len() => {
                if let (Some(high), Some(low)) =
                    (hex_value(bytes[index + 1]), hex_value(bytes[index + 2]))
                {
                    decoded.push((high << 4) | low);
                    index += 3;
                } else {
                    decoded.push(bytes[index]);
                    index += 1;
                }
            }
            byte => {
                decoded.push(byte);
                index += 1;
            }
        }
    }
    String::from_utf8_lossy(&decoded).into_owned()
}

fn hex_value(byte: u8) -> Option<u8> {
    match byte {
        b'0'..=b'9' => Some(byte - b'0'),
        b'a'..=b'f' => Some(byte - b'a' + 10),
        b'A'..=b'F' => Some(byte - b'A' + 10),
        _ => None,
    }
}

fn safe_relative_path(path: &str) -> Option<PathBuf> {
    if path.is_empty() {
        return None;
    }
    let candidate = Path::new(path);
    if candidate
        .components()
        .all(|component| matches!(component, Component::Normal(_)))
    {
        Some(candidate.to_path_buf())
    } else {
        None
    }
}

fn serve_static_file(
    stream: &mut TcpStream,
    site_dir: &str,
    path: &str,
    head: bool,
) -> io::Result<()> {
    let target = Path::new(site_dir).join(path);
    if !target.is_file() {
        return write_text_response(stream, 404, "Not Found", "404 Not Found\n", &[], head);
    }
    serve_file_path(stream, &target, head)
}

fn serve_file_path(stream: &mut TcpStream, target: &Path, head: bool) -> io::Result<()> {
    let data = fs::read(target)?;
    let content_type = get_mime_type(target);
    let headers = [
        ("X-Content-Type-Options", "nosniff".to_string()),
        ("Cache-Control", static_cache_control(target).to_string()),
    ];
    write_response(stream, 200, "OK", content_type, &data, &headers, head)
}

fn write_redirect(
    stream: &mut TcpStream,
    status: u16,
    reason: &str,
    location: &str,
) -> io::Result<()> {
    write_redirect_with_headers(stream, status, reason, location, &[])
}

fn write_redirect_with_headers(
    stream: &mut TcpStream,
    status: u16,
    reason: &str,
    location: &str,
    extra_headers: &[(&str, String)],
) -> io::Result<()> {
    let mut headers = vec![
        ("Location", location.to_string()),
        ("Cache-Control", "no-store".to_string()),
    ];
    headers.extend(
        extra_headers
            .iter()
            .map(|(name, value)| (*name, value.clone())),
    );
    write_response(
        stream,
        status,
        reason,
        "text/plain; charset=utf-8",
        &[],
        &headers,
        false,
    )
}

fn write_html_response(
    stream: &mut TcpStream,
    status: u16,
    reason: &str,
    html: &str,
    headers: &[(&str, String)],
    head: bool,
) -> io::Result<()> {
    write_response(
        stream,
        status,
        reason,
        "text/html; charset=utf-8",
        html.as_bytes(),
        headers,
        head,
    )
}

fn write_text_response(
    stream: &mut TcpStream,
    status: u16,
    reason: &str,
    text: &str,
    headers: &[(&str, String)],
    head: bool,
) -> io::Result<()> {
    write_response(
        stream,
        status,
        reason,
        "text/plain; charset=utf-8",
        text.as_bytes(),
        headers,
        head,
    )
}

fn write_response(
    stream: &mut TcpStream,
    status: u16,
    reason: &str,
    content_type: &str,
    body: &[u8],
    headers: &[(&str, String)],
    head: bool,
) -> io::Result<()> {
    let mut response_head = format!(
        "HTTP/1.1 {} {}\r\nContent-Type: {}\r\nContent-Length: {}\r\nConnection: close\r\nX-CENTL-Origin: rust\r\nX-CENTL-Build: {}\r\n",
        status,
        reason,
        content_type,
        body.len(),
        build_commit()
    );
    for (name, value) in headers {
        response_head.push_str(name);
        response_head.push_str(": ");
        response_head.push_str(value);
        response_head.push_str("\r\n");
    }
    response_head.push_str("\r\n");
    stream.write_all(response_head.as_bytes())?;
    if !head {
        stream.write_all(body)?;
    }
    stream.flush()
}

fn build_commit() -> String {
    env::var("CENTL_BUILD_COMMIT")
        .ok()
        .filter(|value| {
            !value.is_empty()
                && value.len() <= 64
                && value
                    .bytes()
                    .all(|byte| byte.is_ascii_alphanumeric() || byte == b'-' || byte == b'_')
        })
        .unwrap_or_else(|| "unknown".to_string())
}

fn static_cache_control(path: &Path) -> &'static str {
    match path.extension().and_then(|extension| extension.to_str()) {
        Some("css") | Some("png") | Some("jpg") | Some("jpeg") | Some("svg") => {
            "public, max-age=300"
        }
        _ => "no-cache, max-age=0",
    }
}

fn get_mime_type(path: &Path) -> &'static str {
    match path.extension().and_then(|extension| extension.to_str()) {
        Some("html") | Some("htm") => "text/html; charset=utf-8",
        Some("css") => "text/css; charset=utf-8",
        Some("js") => "text/javascript; charset=utf-8",
        Some("png") => "image/png",
        Some("jpg") | Some("jpeg") => "image/jpeg",
        Some("webp") => "image/webp",
        Some("svg") => "image/svg+xml",
        Some("txt") => "text/plain; charset=utf-8",
        Some("json") => "application/json",
        Some("xml") => "application/xml",
        Some("ico") => "image/x-icon",
        _ => "application/octet-stream",
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::engine::HistoryEntry;

    fn temporary_project_root(label: &str) -> PathBuf {
        let nonce = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap_or_default()
            .as_nanos();
        let base = env::temp_dir()
            .canonicalize()
            .unwrap_or_else(|_| env::temp_dir());
        base.join(format!(
            "centl26-project-test-{}-{}-{}",
            label,
            std::process::id(),
            nonce
        ))
    }

    fn sample_history(command: &str, result: &str) -> HistoryEntry {
        HistoryEntry {
            command: command.to_string(),
            result: result.to_string(),
            exact_repr: Some(result.to_string()),
            approximate_repr: None,
            execution_micros: 17,
            success: true,
        }
    }

    fn exchange_lab_request(
        server: Arc<ServerState>,
        build_request: impl FnOnce(&str) -> String,
    ) -> String {
        let listener = TcpListener::bind("127.0.0.1:0").unwrap();
        let authority = listener.local_addr().unwrap().to_string();
        let request = build_request(&authority);
        let worker = thread::spawn(move || {
            let (stream, _) = listener.accept().unwrap();
            handle_lab_connection(stream, server).unwrap();
        });
        let mut stream = TcpStream::connect(&authority).unwrap();
        stream.write_all(request.as_bytes()).unwrap();
        let mut response = String::new();
        stream.read_to_string(&mut response).unwrap();
        worker.join().unwrap();
        response
    }

    #[test]
    fn percent_decoder_preserves_utf8_math() {
        assert_eq!(url_decode("approx%28%CF%80%2C+50%29"), "approx(π, 50)");
    }

    #[test]
    fn form_decoder_handles_plus_and_escaped_plus() {
        assert_eq!(
            extract_form_value("cmd=1%2F3+%2B+5%2F7", "cmd"),
            "1/3 + 5/7"
        );
    }

    #[test]
    fn lab_structured_tools_lower_to_canonical_commands() {
        assert_eq!(
            lab_command_from_body("lab_action=convert&value=100&from_unit=cm&to_unit=m"),
            "physics convert 100 cm m"
        );
        assert_eq!(
            lab_command_from_body("lab_action=es_solve&prime=1009"),
            "es solve 1009"
        );
        assert_eq!(
            lab_command_from_body("lab_action=approximate&expression=sqrt%282%29&digits=40"),
            "approx(sqrt(2), 40)"
        );
    }

    #[test]
    fn centl26_registry_advertises_the_qualified_chemistry_slice_and_project_store() {
        let registry: serde_json::Value =
            serde_json::from_str(lab_template::CAPABILITY_REGISTRY).unwrap();
        let capabilities = registry["capabilities"].as_array().unwrap();
        let chemistry = capabilities
            .iter()
            .find(|capability| capability["id"].as_str() == Some("org.fcf.centl.chemistry.compute"))
            .unwrap();
        assert_eq!(chemistry["status"], "available");
        assert_eq!(
            chemistry["operations"],
            serde_json::json!(["atoms", "balance"])
        );

        let project = capabilities
            .iter()
            .find(|capability| capability["id"].as_str() == Some("org.fcf.centl.project.persist"))
            .unwrap();
        assert_eq!(project["status"], "available");
        assert!(project["assurance"]
            .as_array()
            .unwrap()
            .iter()
            .any(|value| value == "atomic-write"));
        assert!(project["persisted_capabilities"]
            .as_array()
            .unwrap()
            .iter()
            .any(|value| value == "org.fcf.centl.physics.compute"));
        assert!(project["persisted_capabilities"]
            .as_array()
            .unwrap()
            .iter()
            .any(|value| value == "org.fcf.centl.research.erdos_straus"));
    }

    #[test]
    fn static_paths_reject_parent_traversal() {
        assert!(safe_relative_path("assets/fcf-centl-banner.png").is_some());
        assert!(safe_relative_path("../Cargo.toml").is_none());
        assert!(safe_relative_path("manuals/../../Cargo.toml").is_none());
    }

    #[test]
    fn tokens_are_strict_hex_values() {
        assert!(valid_token("0123456789abcdef0123456789abcdef"));
        assert!(!valid_token("../not-a-session"));
        assert!(!valid_token("0123456789abcdef"));
    }

    #[test]
    fn flashes_are_one_time_and_session_scoped() {
        let state = ServerState::new();
        let token = state.store_flash("aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", "result".to_string());
        assert!(state
            .take_flash(&token, "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb")
            .is_none());
        let token = state.store_flash("aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", "result".to_string());
        assert_eq!(
            state.take_flash(&token, "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"),
            Some("result".to_string())
        );
        assert!(state
            .take_flash(&token, "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa")
            .is_none());
    }

    #[test]
    fn reset_session_clears_saved_calculations() {
        let mut state = AppState {
            session: Session::new(),
        };
        state.session.history.push(HistoryEntry {
            command: "22 + 22".to_string(),
            result: "44".to_string(),
            exact_repr: None,
            approximate_repr: None,
            execution_micros: 1,
            success: true,
        });
        reset_session(&mut state);
        assert!(state.session.history.is_empty());
    }

    #[test]
    fn pristine_work_area_contains_no_history_rows() {
        let html = render_pristine_work_area();
        assert!(html.contains("CENTL exact mathematical interpreter ready."));
        assert!(!html.contains("history-item"));
    }

    #[test]
    fn centl26_project_round_trips_notebook_runs_and_revision() {
        let root = temporary_project_root("roundtrip");
        let (mut store, mut session) = ProjectStore::open(root.clone()).unwrap();
        assert_eq!(store.revision, 0);
        session.history.push(HistoryEntry {
            command: "integrate(π * x, x)\n# \"study\"".to_string(),
            result: "(π * (x ^ 2/2)) + C".to_string(),
            exact_repr: None,
            approximate_repr: Some("symbolic enclosure note".to_string()),
            execution_micros: 42,
            success: true,
        });

        store.save(&session).unwrap();
        assert_eq!(store.revision, 1);
        let project_bytes = fs::read(root.join(LAB_PROJECT_FILE)).unwrap();
        let project_json: serde_json::Value = serde_json::from_slice(&project_bytes).unwrap();
        assert_eq!(project_json["schema"], LAB_PROJECT_SCHEMA);
        assert_eq!(project_json["revision"], 1);
        assert_eq!(
            project_json["notebook"]["runs"][0]["command"],
            "integrate(π * x, x)\n# \"study\""
        );

        drop(store);
        let (reopened, restored) = ProjectStore::open(root.clone()).unwrap();
        assert_eq!(reopened.revision, 1);
        assert_eq!(restored.history.len(), 1);
        let entry = &restored.history[0];
        assert_eq!(entry.command, session.history[0].command);
        assert_eq!(entry.result, session.history[0].result);
        assert_eq!(entry.exact_repr, None);
        assert_eq!(
            entry.approximate_repr.as_deref(),
            Some("symbolic enclosure note")
        );
        assert_eq!(entry.execution_micros, 42);

        drop(reopened);
        fs::remove_dir_all(root).unwrap();
    }

    #[test]
    fn centl26_project_atomic_save_replaces_cleanly() {
        let root = temporary_project_root("atomic");
        let (mut store, mut session) = ProjectStore::open(root.clone()).unwrap();
        session.history.push(sample_history("1 + 1", "2"));
        store.save(&session).unwrap();
        session.history.push(sample_history("2 + 2", "4"));
        store.save(&session).unwrap();

        drop(store);
        let (reopened, restored) = ProjectStore::open(root.clone()).unwrap();
        assert_eq!(reopened.revision, 2);
        assert_eq!(restored.history.len(), 2);
        assert_eq!(restored.history[1].command, "2 + 2");
        assert!(fs::read_dir(&root).unwrap().all(|entry| !entry
            .unwrap()
            .file_name()
            .to_string_lossy()
            .contains(".new-")));

        #[cfg(unix)]
        {
            let root_mode = fs::metadata(&root).unwrap().permissions().mode() & 0o777;
            let file_mode = fs::metadata(root.join(LAB_PROJECT_FILE))
                .unwrap()
                .permissions()
                .mode()
                & 0o777;
            assert_eq!(root_mode, 0o700);
            assert_eq!(file_mode, 0o600);
        }

        drop(reopened);
        fs::remove_dir_all(root).unwrap();
    }

    #[test]
    fn centl26_project_rejects_wrong_schema_and_excess_runs() {
        let root = temporary_project_root("validation");
        validate_project_root(&root).unwrap();
        fs::write(
            root.join(LAB_PROJECT_FILE),
            br#"{"schema":"centl.project/999","revision":1,"notebook":{"id":"notebook-01","runs":[]}}"#,
        )
        .unwrap();
        let error = ProjectStore::open(root.clone()).unwrap_err();
        assert_eq!(error.kind(), io::ErrorKind::InvalidData);

        fs::remove_file(root.join(LAB_PROJECT_FILE)).unwrap();
        let oversized = File::create(root.join(LAB_PROJECT_FILE)).unwrap();
        oversized
            .set_len((MAX_LAB_PROJECT_BYTES + 1) as u64)
            .unwrap();
        drop(oversized);
        let error = ProjectStore::open(root.clone()).unwrap_err();
        assert_eq!(error.kind(), io::ErrorKind::InvalidData);

        fs::remove_file(root.join(LAB_PROJECT_FILE)).unwrap();
        let (mut store, mut session) = ProjectStore::open(root.clone()).unwrap();
        for index in 0..=MAX_LAB_HISTORY_ENTRIES {
            session
                .history
                .push(sample_history(&format!("{index} + 1"), &index.to_string()));
        }
        let error = store.save(&session).unwrap_err();
        assert_eq!(error.kind(), io::ErrorKind::InvalidData);
        assert!(!root.join(LAB_PROJECT_FILE).exists());

        drop(store);
        fs::remove_dir_all(root).unwrap();
    }

    #[test]
    fn centl26_server_reopens_the_same_default_project() {
        let root = temporary_project_root("restart");
        let server = ServerState::new_lab_at(root.clone()).unwrap();
        let (_, state, is_new) = server.session_for(None);
        assert!(is_new);
        {
            let mut state = state.lock().unwrap();
            crate::engine::evaluate("19 * 23", &mut state.session).unwrap();
            server.persist_lab_project(&state).unwrap();
        }
        drop(server);

        let restarted = ServerState::new_lab_at(root.clone()).unwrap();
        let (_, restored, _) = restarted.session_for(None);
        let restored = restored.lock().unwrap();
        assert_eq!(restored.session.history.len(), 1);
        assert_eq!(restored.session.history[0].command, "19 * 23");
        assert_eq!(restored.session.history[0].result, "437");

        drop(restored);
        drop(restarted);
        fs::remove_dir_all(root).unwrap();
    }

    #[test]
    fn centl26_restart_preserves_physics_and_research_evidence() {
        let root = temporary_project_root("domain-restart");
        let server = ServerState::new_lab_at(root.clone()).unwrap();
        let (_, state, _) = server.session_for(None);
        {
            let mut state = state.lock().unwrap();
            let (_, error, physics, _) = handle_command("physics convert 100 cm m", &mut state);
            assert!(error.is_none());
            assert!(physics.is_some());
            let (solve, error, _, _) = handle_command("es solve 1009", &mut state);
            assert!(error.is_none());
            assert!(solve.is_some());
            let (_, error, _, hunt) = handle_command("es", &mut state);
            assert!(error.is_none());
            assert!(hunt.is_some());
            server.persist_lab_project(&state).unwrap();
        }
        drop(state);
        drop(server);

        let restarted = ServerState::new_lab_at(root.clone()).unwrap();
        let (_, restored, _) = restarted.session_for(None);
        let restored = restored.lock().unwrap();
        assert_eq!(restored.session.history.len(), 3);
        assert!(restored.session.history[0]
            .exact_repr
            .as_deref()
            .unwrap()
            .contains("org.fcf.centl.physics.compute"));
        assert!(restored.session.history[1]
            .exact_repr
            .as_deref()
            .unwrap()
            .contains("org.fcf.centl.research.erdos_straus/solve"));
        assert!(restored.session.history[2]
            .exact_repr
            .as_deref()
            .unwrap()
            .contains("org.fcf.centl.research.erdos_straus/hunt"));

        drop(restored);
        drop(restarted);
        fs::remove_dir_all(root).unwrap();
    }

    #[test]
    fn centl26_lab_mutations_require_exact_origin_and_process_cookie() {
        let root = temporary_project_root("auth");
        let server = ServerState::new_lab_at(root.clone()).unwrap();
        let (session_id, _, _) = server.session_for(None);
        let authority = "127.0.0.1:2626";
        let mut headers = HashMap::new();
        headers.insert("host".to_string(), authority.to_string());
        headers.insert("origin".to_string(), format!("http://{authority}"));
        headers.insert(
            "cookie".to_string(),
            format!("{}={}", LAB_SESSION_COOKIE, session_id),
        );
        let request = HttpRequest {
            method: "POST".to_string(),
            target: "/api/run".to_string(),
            headers,
            body: b"lab_action=calculate&cmd=1%2B1".to_vec(),
        };
        let cookie = request
            .headers
            .get("cookie")
            .and_then(|value| cookie_value(value, LAB_SESSION_COOKIE));
        assert!(lab_host_is_authorized(&request, authority));
        assert!(lab_mutation_is_authorized(
            &request,
            &server,
            authority,
            cookie.as_deref()
        ));
        assert!(!lab_mutation_is_authorized(
            &request,
            &server,
            authority,
            Some("00000000000000000000000000000000")
        ));
        assert!(!lab_host_is_authorized(&request, "127.0.0.1:9999"));

        let mut wrong_origin = request.headers.clone();
        wrong_origin.insert("origin".to_string(), "https://attacker.invalid".to_string());
        let wrong_origin = HttpRequest {
            headers: wrong_origin,
            ..request
        };
        assert!(!lab_mutation_is_authorized(
            &wrong_origin,
            &server,
            authority,
            cookie.as_deref()
        ));
        assert!(!lab_mutation_is_authorized(
            &wrong_origin,
            &server,
            authority,
            Some("00000000000000000000000000000000")
        ));
        assert!(lab_session_cookie_header(&session_id).contains("SameSite=Strict"));

        drop(server);
        fs::remove_dir_all(root).unwrap();
    }

    #[test]
    #[ignore = "requires permission to bind an ephemeral loopback test socket"]
    fn centl26_http_gate_mints_cookie_then_accepts_only_authenticated_post() {
        let root = temporary_project_root("http-auth");
        let server = Arc::new(ServerState::new_lab_at(root.clone()).unwrap());

        let forbidden = exchange_lab_request(Arc::clone(&server), |authority| {
            let body = "lab_action=calculate&cmd=2%2B3";
            format!(
                "POST /api/run HTTP/1.1\r\nHost: {authority}\r\nOrigin: https://attacker.invalid\r\nContent-Type: application/x-www-form-urlencoded\r\nContent-Length: {}\r\nConnection: close\r\n\r\n{body}",
                body.len()
            )
        });
        assert!(forbidden.starts_with("HTTP/1.1 403 Forbidden"));

        let initial = exchange_lab_request(Arc::clone(&server), |authority| {
            format!("GET / HTTP/1.1\r\nHost: {authority}\r\nConnection: close\r\n\r\n")
        });
        assert!(initial.starts_with("HTTP/1.1 200 OK"));
        let cookie = initial
            .lines()
            .find_map(|line| line.strip_prefix("Set-Cookie: "))
            .and_then(|value| value.split(';').next())
            .unwrap()
            .to_string();

        let accepted = exchange_lab_request(Arc::clone(&server), |authority| {
            let body = "lab_action=calculate&cmd=2%2B3";
            format!(
                "POST /api/run HTTP/1.1\r\nHost: {authority}\r\nOrigin: http://{authority}\r\nCookie: {cookie}\r\nContent-Type: application/x-www-form-urlencoded\r\nContent-Length: {}\r\nConnection: close\r\n\r\n{body}",
                body.len()
            )
        });
        assert!(accepted.starts_with("HTTP/1.1 200 OK"));

        let (_, state, _) = server.session_for(None);
        assert_eq!(state.lock().unwrap().session.history.len(), 1);
        drop(state);
        drop(server);

        let (_, restored) = ProjectStore::open(root.clone()).unwrap();
        assert_eq!(restored.history.len(), 1);
        assert_eq!(restored.history[0].result, "5");
        fs::remove_dir_all(root).unwrap();
    }

    #[test]
    fn centl26_project_lock_rejects_a_second_backend_writer() {
        let root = temporary_project_root("exclusive-lock");
        let (first, _) = ProjectStore::open(root.clone()).unwrap();
        let error = ProjectStore::open(root.clone()).unwrap_err();
        assert_eq!(error.kind(), io::ErrorKind::WouldBlock);
        drop(first);
        let (reopened, _) = ProjectStore::open(root.clone()).unwrap();
        drop(reopened);
        fs::remove_dir_all(root).unwrap();
    }

    #[cfg(unix)]
    #[test]
    fn centl26_project_root_never_chmods_existing_or_follows_links() {
        use std::os::unix::fs::symlink;

        let root = temporary_project_root("existing-mode");
        fs::create_dir(&root).unwrap();
        fs::set_permissions(&root, fs::Permissions::from_mode(0o750)).unwrap();
        validate_project_root(&root).unwrap();
        assert_eq!(
            fs::metadata(&root).unwrap().permissions().mode() & 0o777,
            0o750
        );
        fs::remove_dir_all(&root).unwrap();

        let base = temporary_project_root("linked-ancestor");
        let real = base.join("real");
        let linked = base.join("linked");
        fs::create_dir_all(&real).unwrap();
        symlink(&real, &linked).unwrap();
        let error = validate_project_root(&linked.join("project")).unwrap_err();
        assert_eq!(error.kind(), io::ErrorKind::PermissionDenied);
        fs::remove_dir_all(base).unwrap();

        assert!(validate_project_root(Path::new("/tmp")).is_err());
        assert!(validate_project_root(Path::new("/tmp/centl26/project")).is_err());
        assert!(validate_project_root(Path::new("/private/tmp/centl26/project")).is_err());
        assert!(validate_project_root(Path::new("/var/tmp/centl26/project")).is_err());
    }

    #[cfg(unix)]
    #[test]
    fn centl26_project_rejects_shared_writable_ancestors_and_linked_lock_files() {
        use std::os::unix::fs::symlink;

        let base = temporary_project_root("writable-ancestor");
        fs::create_dir_all(&base).unwrap();
        let shared = base.join("shared");
        fs::create_dir(&shared).unwrap();
        fs::set_permissions(&shared, fs::Permissions::from_mode(0o777)).unwrap();
        assert!(validate_project_root(&shared.join("project")).is_err());
        fs::remove_dir_all(&base).unwrap();

        let root = temporary_project_root("linked-lock");
        validate_project_root(&root).unwrap();
        let target = root.join("do-not-open-as-lock");
        fs::write(&target, b"unchanged").unwrap();
        symlink(&target, root.join(LAB_PROJECT_LOCK_FILE)).unwrap();
        assert!(ProjectStore::open(root.clone()).is_err());
        assert_eq!(fs::read(&target).unwrap(), b"unchanged");
        fs::remove_dir_all(root).unwrap();
    }
}
