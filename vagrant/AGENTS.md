# Project Notes

- Do not propose or configure workflows that require running Vagrant or QEMU as root.
- For the Vagrant QEMU provider, do not use the point-to-point socket networking pattern where the master listens and the worker connects.
