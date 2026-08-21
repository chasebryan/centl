use serde_json::{json, Value};
use std::env;
use std::path::Path;

#[cfg(unix)]
use std::os::unix::fs::PermissionsExt;

pub(crate) const CANONICAL_MATH_ENV: &str = "CENTL26_CENTL_BIN";
pub(crate) const LEGACY_CANONICAL_MATH_ENV: &str = "CENTL_ENGINE_BIN";
pub(crate) const CHEMISTRY_ENV: &str = "CENTL26_CHEM_BIN";
pub(crate) const SCI_ENV: &str = "CENTL26_SCI_BIN";
pub(crate) const CPS_ENV: &str = "CENTL26_CPS_BIN";
pub(crate) const MIRAGE_ENV: &str = "CENTL26_MIRAGE_BIN";
pub(crate) const PHYSICS_ENV: &str = "CENTL26_PHYSICS_BIN";

#[derive(Clone, Debug, PartialEq, Eq)]
pub(crate) struct ProviderResolution {
    pub command: String,
    pub source: &'static str,
    pub available: bool,
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub(crate) struct RuntimeProviders {
    pub canonical_math: ProviderResolution,
    pub chemistry: ProviderResolution,
    pub sci: ProviderResolution,
    pub cps: ProviderResolution,
    pub mirage: ProviderResolution,
    pub physics: ProviderResolution,
}

impl RuntimeProviders {
    pub(crate) fn detect() -> Self {
        Self {
            canonical_math: resolve_provider(
                CANONICAL_MATH_ENV,
                Some(LEGACY_CANONICAL_MATH_ENV),
                "centl",
            ),
            chemistry: resolve_provider(CHEMISTRY_ENV, None, "centl-chem"),
            sci: resolve_provider(SCI_ENV, None, "centl-sci"),
            cps: resolve_provider(CPS_ENV, None, "centl-cps"),
            mirage: resolve_provider(MIRAGE_ENV, None, "centl-mirage"),
            physics: resolve_provider(PHYSICS_ENV, None, "centl-physics"),
        }
    }
}

pub(crate) fn canonical_math_provider() -> ProviderResolution {
    resolve_provider(CANONICAL_MATH_ENV, Some(LEGACY_CANONICAL_MATH_ENV), "centl")
}

pub(crate) fn chemistry_provider() -> ProviderResolution {
    resolve_provider(CHEMISTRY_ENV, None, "centl-chem")
}

pub(crate) fn sci_provider() -> ProviderResolution {
    resolve_provider(SCI_ENV, None, "centl-sci")
}

pub(crate) fn cps_provider() -> ProviderResolution {
    resolve_provider(CPS_ENV, None, "centl-cps")
}

pub(crate) fn mirage_provider() -> ProviderResolution {
    resolve_provider(MIRAGE_ENV, None, "centl-mirage")
}

#[allow(dead_code)]
pub(crate) fn physics_provider() -> ProviderResolution {
    resolve_provider(PHYSICS_ENV, None, "centl-physics")
}

fn resolve_provider(
    primary_environment: &str,
    legacy_environment: Option<&str>,
    binary_name: &str,
) -> ProviderResolution {
    let primary = environment_value(primary_environment);
    let legacy = legacy_environment.and_then(environment_value);
    let sibling = env::current_exe()
        .ok()
        .and_then(|executable| executable.parent().map(|parent| parent.join(binary_name)))
        .filter(|candidate| command_path_is_available(candidate));
    let (command, source) = select_provider_command(
        primary.as_deref(),
        legacy.as_deref(),
        sibling.as_deref(),
        binary_name,
    );
    let available = command_is_available(&command);
    ProviderResolution {
        command,
        source,
        available,
    }
}

fn environment_value(name: &str) -> Option<String> {
    env::var(name)
        .ok()
        .map(|value| value.trim().to_string())
        .filter(|value| !value.is_empty())
}

fn select_provider_command(
    primary: Option<&str>,
    legacy: Option<&str>,
    sibling: Option<&Path>,
    binary_name: &str,
) -> (String, &'static str) {
    if let Some(command) = primary {
        return (command.to_string(), "product-environment");
    }
    if let Some(command) = legacy {
        return (command.to_string(), "legacy-environment");
    }
    if let Some(command) = sibling {
        return (command.to_string_lossy().into_owned(), "sibling-binary");
    }
    (binary_name.to_string(), "path-search")
}

fn command_is_available(command: &str) -> bool {
    let path = Path::new(command);
    if path.is_absolute() || path.components().count() > 1 {
        return command_path_is_available(path);
    }

    env::var_os("PATH")
        .map(|path| {
            env::split_paths(&path)
                .map(|directory| directory.join(command))
                .any(|candidate| command_path_is_available(&candidate))
        })
        .unwrap_or(false)
}

fn command_path_is_available(path: &Path) -> bool {
    let Ok(metadata) = path.metadata() else {
        return false;
    };
    if !metadata.is_file() {
        return false;
    }
    #[cfg(unix)]
    {
        metadata.permissions().mode() & 0o111 != 0
    }
    #[cfg(not(unix))]
    {
        true
    }
}

pub(crate) fn runtime_registry(
    base_registry: &str,
    project_store_available: bool,
) -> Result<Value, serde_json::Error> {
    runtime_registry_with_providers(
        base_registry,
        project_store_available,
        &RuntimeProviders::detect(),
    )
}

fn runtime_registry_with_providers(
    base_registry: &str,
    project_store_available: bool,
    providers: &RuntimeProviders,
) -> Result<Value, serde_json::Error> {
    let mut registry: Value = serde_json::from_str(base_registry)?;
    set_capability_status(
        &mut registry,
        "org.fcf.centl.numerics.enclose",
        providers.canonical_math.available,
        "The canonical CENTL provider is not available in this runtime.",
    );
    set_capability_status(
        &mut registry,
        "org.fcf.centl.chemistry.compute",
        providers.chemistry.available,
        "The CENTL Chemistry provider is not available in this runtime.",
    );
    set_capability_status(
        &mut registry,
        "org.fcf.centl.sci.interpret",
        providers.sci.available,
        "The CENTL-SCi provider is not available in this runtime.",
    );
    set_capability_status(
        &mut registry,
        "org.fcf.centl.mirage.develop",
        providers.mirage.available,
        "The CENTL-MIRAGE development engine is not available in this runtime.",
    );
    set_capability_status(
        &mut registry,
        "org.fcf.centl.project.persist",
        project_store_available,
        "No writable CentL26 project store is attached.",
    );

    if let Some(root) = registry.as_object_mut() {
        root.insert(
            "runtime_status".to_string(),
            json!({
                "mode": "offline-local",
                "project_store": if project_store_available { "available" } else { "unavailable" },
                "providers": {
                    "centl": provider_status(&providers.canonical_math),
                    "centl-chem": provider_status(&providers.chemistry),
                    "centl-sci": provider_status(&providers.sci),
                    "centl-cps": provider_status(&providers.cps),
                    "centl-mirage": provider_status(&providers.mirage),
                    "centl-physics": provider_status(&providers.physics),
                }
            }),
        );
    }
    Ok(registry)
}

fn set_capability_status(
    registry: &mut Value,
    capability_id: &str,
    available: bool,
    unavailable_reason: &str,
) {
    let Some(capabilities) = registry
        .get_mut("capabilities")
        .and_then(Value::as_array_mut)
    else {
        return;
    };
    let Some(capability) = capabilities
        .iter_mut()
        .find(|capability| capability.get("id").and_then(Value::as_str) == Some(capability_id))
    else {
        return;
    };
    let Some(capability) = capability.as_object_mut() else {
        return;
    };
    capability.insert(
        "status".to_string(),
        Value::String(
            if available {
                "available"
            } else {
                "unavailable"
            }
            .to_string(),
        ),
    );
    capability.insert("runtime_available".to_string(), Value::Bool(available));
    if available {
        capability.remove("unavailable_reason");
    } else {
        capability.insert(
            "unavailable_reason".to_string(),
            Value::String(unavailable_reason.to_string()),
        );
    }
}

fn provider_status(provider: &ProviderResolution) -> Value {
    json!({
        "status": if provider.available { "available" } else { "unavailable" },
        "source": provider.source,
    })
}

pub(crate) fn available_capability_count(registry: &Value) -> usize {
    registry
        .get("capabilities")
        .and_then(Value::as_array)
        .map(|capabilities| {
            capabilities
                .iter()
                .filter(|capability| {
                    capability.get("status").and_then(Value::as_str) == Some("available")
                })
                .count()
        })
        .unwrap_or(0)
}

pub(crate) fn capability_status<'a>(registry: &'a Value, id: &str) -> Option<&'a str> {
    registry
        .get("capabilities")?
        .as_array()?
        .iter()
        .find(|capability| capability.get("id").and_then(Value::as_str) == Some(id))?
        .get("status")?
        .as_str()
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::path::PathBuf;

    fn provider(available: bool) -> ProviderResolution {
        ProviderResolution {
            command: "/test/provider".to_string(),
            source: "product-environment",
            available,
        }
    }

    #[test]
    fn canonical_provider_prefers_the_product_environment_then_legacy_fallback() {
        let sibling = PathBuf::from("/bundle/centl");
        assert_eq!(
            select_provider_command(
                Some("/configured/centl"),
                Some("/legacy/centl"),
                Some(&sibling),
                "centl"
            ),
            ("/configured/centl".to_string(), "product-environment")
        );
        assert_eq!(
            select_provider_command(None, Some("/legacy/centl"), Some(&sibling), "centl"),
            ("/legacy/centl".to_string(), "legacy-environment")
        );
        assert_eq!(
            select_provider_command(None, None, Some(&sibling), "centl"),
            ("/bundle/centl".to_string(), "sibling-binary")
        );
        assert_eq!(
            select_provider_command(None, None, None, "centl"),
            ("centl".to_string(), "path-search")
        );
    }

    #[test]
    fn runtime_registry_never_promotes_missing_optional_providers() {
        let providers = RuntimeProviders {
            canonical_math: provider(false),
            chemistry: provider(false),
            sci: provider(false),
            cps: provider(false),
            mirage: provider(false),
            physics: provider(false),
        };
        let registry = runtime_registry_with_providers(
            super::super::lab_template::CAPABILITY_REGISTRY,
            true,
            &providers,
        )
        .unwrap();
        assert_eq!(
            capability_status(&registry, "org.fcf.centl.numerics.enclose"),
            Some("unavailable")
        );
        assert_eq!(
            capability_status(&registry, "org.fcf.centl.chemistry.compute"),
            Some("unavailable")
        );
        assert_eq!(
            capability_status(&registry, "org.fcf.centl.sci.interpret"),
            Some("unavailable")
        );
        assert_eq!(
            capability_status(&registry, "org.fcf.centl.mirage.develop"),
            Some("unavailable")
        );
        assert_eq!(
            capability_status(&registry, "org.fcf.centl.project.persist"),
            Some("available")
        );
    }

    #[test]
    fn runtime_registry_promotes_only_present_optional_providers() {
        let providers = RuntimeProviders {
            canonical_math: provider(true),
            chemistry: provider(true),
            sci: provider(true),
            cps: provider(true),
            mirage: provider(true),
            physics: provider(true),
        };
        let registry = runtime_registry_with_providers(
            super::super::lab_template::CAPABILITY_REGISTRY,
            false,
            &providers,
        )
        .unwrap();
        assert_eq!(
            capability_status(&registry, "org.fcf.centl.numerics.enclose"),
            Some("available")
        );
        assert_eq!(
            capability_status(&registry, "org.fcf.centl.chemistry.compute"),
            Some("available")
        );
        assert_eq!(
            capability_status(&registry, "org.fcf.centl.sci.interpret"),
            Some("available")
        );
        assert_eq!(
            capability_status(&registry, "org.fcf.centl.mirage.develop"),
            Some("available")
        );
        assert_eq!(
            capability_status(&registry, "org.fcf.centl.project.persist"),
            Some("unavailable")
        );
    }
}
