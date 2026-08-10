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
preserve hypothetical macOS or Windows support.

Support for another operating system may be reintroduced later from a stable
CENTL specification when there is a concrete user need and enough engineering
capacity to maintain it honestly. Until then, the support hierarchy is simply:

1. **GNU/Linux — supported reference platform.**
2. **macOS — unsupported.**
3. **Windows — unsupported.**
