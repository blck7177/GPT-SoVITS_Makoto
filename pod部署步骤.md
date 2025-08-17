目前的脚本体系已经可以覆盖“一键部署→下载所有权重→生成 `tts_infer.yaml`→启动 API”的完整闭环；只需按下列顺序执行即可：

1. 依赖安装（含虚拟环境）  
   ```bash
   bash scripts/bootstrap.sh
   # ⚙️ 进入 .venv 环境
   source .venv/bin/activate
   ```

2. 下载你发布的训练权重 + 参考音频  
   ```bash
   export GITHUB_TOKEN=<你的 GitHub PAT>      # 必需
   bash scripts/download_release_weights.sh    # 如需指定其他 owner/repo/tag 见 --help
   ```

3. 下载中文前端 / G2PWModel / (可选)SV 预训练，并生成 `configs/tts_infer.yaml`  
   ```bash
   bash scripts/fetch_models.sh                # 可用 --t2s / --vits / --skip-sv 参数
   ```

4. 启动推理 API（或 WebUI）  
   ```bash
   bash scripts/start.sh                       # 默认：python api_v2.py -a 0.0.0.0 -p 9880 ...
   ```

-------------------------------------------------
环境变量一览
1. **GITHUB_TOKEN**（必需）  
   - 作用：通过 GitHub API 下载私有 release 资产，或绕过匿名速率限制  
   - 权限：`repo` 即可

2. （可选）脚本参数  
   - `scripts/download_release_weights.sh`  
     • `--owner` `--repo` `--tag`：覆盖默认仓库/标签  
   - `scripts/fetch_models.sh`  
     • `--t2s` `--vits`：自定义你训练好的 S1/S2 权重路径  
     • `--skip-sv`：跳过 SV 模型下载

3. 其他常见可选 ENV  
   - `HF_ENDPOINT` / `HTTPS_PROXY` 等，用于 HuggingFace 镜像或代理；脚本本身不依赖，但可加快下载

只要设置好 `GITHUB_TOKEN` 并按照 1→4 步执行，就能完成整个 v2 ProPlus 推理环境的构建与启动。如果还想把 2、3 两步内嵌到 `bootstrap.sh` 以实现真正“一键”，可以再告诉我！