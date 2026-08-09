# CENTL-SCi platform support

Linux is the reference platform for CENTL-SCi. During the early development
series, Linux is the primary development and release-blocking target.

Windows support is experimental and best-effort during the early development
series. Windows-specific failures do not block scientific feature development
unless they indicate a cross-platform correctness or safety problem.

This policy is an engineering-resource decision, not opposition to Windows.
Supporting Windows can consume substantial development time through
platform-specific build behavior, dependency management, packaging, CI,
filesystem differences, installer maintenance, and portability work. For an
early scientific project, those costs must be balanced against work on
mathematical correctness, physics capability, verification, performance, and the
scientific interface.

CENTL-SCi intends to retain Windows support where practical, but Windows-specific
work must not dictate the pace of scientific development. Additional engineering
resources or sponsorship could make sustained Windows support substantially more
practical without diverting effort from scientific advancement.

macOS remains a supported native target where the existing portable runtime and
release pipeline remain practical.

The support hierarchy is:

1. **Linux — reference platform:** primary development, full validation, and
   release-blocking correctness target.
2. **macOS — supported native platform:** maintained where the portable build and
   release path remains practical.
3. **Windows x86_64 — experimental/best-effort:** supported when practical;
   Windows-only failures are non-blocking unless they reveal a shared correctness
   or safety defect.

The project should continue avoiding unnecessary platform lock-in in shared code.
The distinction is between portability as a design goal and platform-specific
work as a release requirement.
