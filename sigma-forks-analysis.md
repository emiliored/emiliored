# 🔀 Análisis de Forks: pySigma-backend-cortexxdr & sigconverter.io

## Contexto

Este documento resume los cambios realizados en mis forks respecto a sus repositorios originales, explicando la necesidad de cada modificación.

---

## 1. `emiliored/pySigma-backend-cortexxdr`

**Fork de:** [`7RedViolin/pySigma-backend-cortexxdr`](https://github.com/7RedViolin/pySigma-backend-cortexxdr)

Este fue el punto de partida. El repositorio original tenía **bugs en el pipeline de mapeo de campos** para Cortex XDR. El maintainer original no acepta PRs de desconocidos, por lo que fue necesario hacer un fork para aplicar los parches.

### Cambios realizados

#### `sigma/pipelines/cortexxdr/cortexxdr.py` — Corrección de mapeo de campos

| Categoría | Campo original (incorrecto) | Campo corregido |
|---|---|---|
| `file_*` | `action_file_name` | `action_file_path` |
| `file_*` | `action_file_previous_file_name` | `action_file_previous_file_path` |
| `file_*` | `sha256`, `md5` (no mapeados) | `action_file_sha256` / `action_file_md5` |
| `network_connection` | `DestinationPort/Ip` → `[local, remote]` (ambiguo) | Destination → `remote`, Source → `local` |
| `network_connection` | `Initiated` (no mapeado) | `action_network_success` |

#### `pyproject.toml` — Versión

La versión estaba en `0.0.0` (sin publicar). Actualizada a `0.1.5` para poder referenciarla como dependencia instalable desde Git.

### ¿Por qué era necesario?

Los mapeos incorrectos hacían que las reglas Sigma generadas para Cortex XDR usaran nombres de campo inexistentes en la API de XDR, produciendo queries XQL inválidas o con resultados erróneos.

> Parches aplicados a partir del trabajo de [v1ctorp1vert](https://github.com/7RedViolin/pySigma-backend-cortexxdr/pull/18). ❤️

---

## 2. `emiliored/sigconverter.io`

**Fork de:** [`magicsword-io/sigconverter.io`](https://github.com/magicsword-io/sigconverter.io)

Este fork fue necesario para **integrar el backend corregido** del fork anterior y resolver un problema de compatibilidad con Docker en Windows.

### Cambios realizados

#### `backend/*/pyproject.toml` (versiones 1.0.3 a 1.0.6) — Sustitución de dependencia

```diff
- "pysigma-backend-cortexxdr==0.1.5"
+ "pysigma-backend-cortexxdr @ git+https://github.com/emiliored/pySigma-backend-cortexxdr.git@0.1.5"
```

Apunta directamente al fork corregido en lugar del paquete oficial de PyPI.

> ⚠️ En las versiones más nuevas del backend (`2.0.0` en adelante), `pysigma-backend-cortexxdr` fue directamente **eliminado** de las dependencias, ya que esas versiones no incluyen soporte para Cortex XDR en el original.

#### `Dockerfile` — Fix de CRLF y dependencia de `git`

```dockerfile
RUN find /app -type f -exec sed -i 's/\r$//' {} +   # Elimina saltos de línea CRLF (Windows)
RUN apt update && apt install -y git                 # Necesario para instalar dependencias desde Git
```

Sin `git` instalado en el contenedor, la dependencia `git+https://...` fallaría al momento del `pip install`. El fix de CRLF resuelve problemas al construir la imagen en sistemas Windows.

> Fix de CRLF gracias a [krdmnbrk](https://github.com/magicsword-io/sigconverter.io/pull/60). ❤️

#### `backend/setup-sigma-plugins.sh`

Se añadió `uv lock` antes del `uv sync` para asegurar que el lockfile esté generado antes de la instalación en modo frozen.

---

## 🧩 Relación entre ambos forks

El flujo es claro y coherente:

```
Bug en campos XQL de Cortex XDR
        ↓
Fork de pySigma-backend-cortexxdr
→ Corrección de mapeos + versión 0.1.5
        ↓
Fork de sigconverter.io
→ Apunta al backend corregido + arreglos Docker para poder instalarlo
```

Se realizó un **parche en cadena**: se corrigió el backend de bajo nivel y luego se adaptó la herramienta de alto nivel para consumir la versión corregida, ya que los canales oficiales no estaban disponibles para hacer contribuciones directas.

---

*Actualizado el 16/06/2026*
