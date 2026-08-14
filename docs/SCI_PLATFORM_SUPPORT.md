# CENTL-SCi platform support

CENTL and CENTL-SCi currently support **GNU/Linux only**.

Linux is the reference platform, the primary development environment, the native
release target, and the only release-blocking platform for the Caramels series.
Build, test, packaging, installer, filesystem, local-model, workspace, extension,
and self-extension behavior are specified and validated against Linux.

macOS and Windows are currently **unsupported**. They may continue to work in
parts of the codebase because CENTL avoids unnecessary platform lock-in where
portable code is natural, but the project makes no compatibility, packaging,
installer, CI, or release promise for either operating system. Failures that are
specific to macOS or Windows do not block Linux development or a CENTL release.

This is an engineering-scope decision. CENTL-SCi increasingly depends on
operating-system-sensitive behavior including persistent terminal interaction,
subprocess execution, local model hosting, native extension loading, workspace
mutation, snapshots, symlink and path safety, packaging, and installation.
Defining one reference operating environment lets those contracts be implemented
and tested rigorously without multiplying platform-specific work while the
scientific system is still developing rapidly.

Shared code should remain portable when doing so is simple and does not weaken or
complicate the Linux implementation. The project should not add abstraction,
compatibility branches, CI jobs, packaging machinery, or release gates solely to
preserve hypothetical macOS or Windows support during the current rapid-development
period.

## Future direction: Three Horizons

CENTL's current compass directive is to use the Linux-first period to deepen and
stabilize the system, then deliberately work toward a future Oasis-qualified release
set for **GNU/Linux, macOS, and Windows**.

The preferred horizon is the late-December 2026 / New Year 2027 window, but this is
an aspirational direction rather than a release promise. The schedule, architecture
matrix, packaging strategy, and version number may change as the implementation and
qualification evidence improve.

Cross-platform restoration will not be considered complete merely because CENTL
compiles on all three operating systems. A supported target must earn a maintained
build, installation, runtime, conformance, hardening, and Oasis qualification path
with the same mathematical meaning and trust boundaries as the other supported
targets.

The Linux-first policy remains authoritative until a later Oasis release explicitly
changes it. In particular, macOS and Windows failures do not currently block Mirage
experimentation or the existing Linux product line.

See [CENTL: Three Horizons](THREE-HORIZONS.md) for the full compass directive.

Until then, the support hierarchy is:

1. **GNU/Linux - supported reference platform.**
2. **macOS - unsupported, future Three Horizons target.**
3. **Windows - unsupported, future Three Horizons target.**
