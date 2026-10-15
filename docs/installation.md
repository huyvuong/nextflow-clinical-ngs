# Environment Setup Targets WSL2 Ubuntu and Docker Reproducibility

## Prerequisites

1. **WSL2 Ubuntu (22.04 LTS or 24.04 LTS)** on Windows 10/11 (recommended 16 GB system RAM, with 12 GB allocated in `.wslconfig`).
2. **Java 17 or 21 LTS**:
   ```bash
   sudo apt update && sudo apt install -y openjdk-17-jre-headless
   java -version
   ```
3. **Nextflow (>= 23.04.0)**:
   ```bash
   curl -s https://get.nextflow.io | bash
   sudo mv nextflow /usr/local/bin/
   nextflow -version
   ```
4. **Docker Desktop (with WSL2 backend enabled)** or native Docker Engine:
   ```bash
   docker --version
   ```
5. **nf-test (Optional, for running automated test suites)**:
   ```bash
   curl -fsSL https://code.askimed.com/install/nf-test | bash
   sudo mv nf-test /usr/local/bin/
   ```

## Recommended WSL2 Memory Tuning (`.wslconfig`)

On a 16 GB Windows machine, create `%UserProfile%\.wslconfig` to prevent host memory exhaustion during GATK4 and BWA-MEM2 execution:

```ini
[wsl2]
memory=12GB
processors=4
swap=4GB
```
