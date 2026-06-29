---
license: apache-2.0
base_model: Qwen/Qwen3.5-9B
base_model_relation: quantized
language:
- en
pipeline_tag: image-text-to-text
library_name: gguf
tags:
- gguf
- llama.cpp
- quantized
- qwen3.5
- long-context
- function-calling
- multimodal
- vision
---

# HeavyD-9B-GGUF

GGUF quantizations of a Qwen3.5-9B fine-tune for [llama.cpp](https://github.com/ggml-org/llama.cpp), Ollama, LM Studio, jan, KoboldCpp, and other GGUF runtimes.

HeavyD-9B is a 9B-parameter model built on the Qwen3.5-9B architecture. It supports native function calling per the Qwen3.5 spec and ships with a 1,048,576-token (1M) context window via YaRN rope-scaling enabled by default. It is a reasoning model: responses open with a `<think>...</think>` block before the final answer.

---

## Try it now

The `.gguf` weights are not in this git repo — they're multi-GB binaries hosted on Hugging Face. Two ways to get running:

**Ollama (easiest — it handles the engine):**

```bash
ollama run hf.co/empero-ai/Qwythos-9B-Claude-Mythos-5-1M-GGUF:Q4_K_M
```

**Helper script (downloads the quant + runs llama.cpp):**

```bash
./scripts/try.sh                 # chat, Q4_K_M, GPU if available
QUANT=Q5_K_M ./scripts/try.sh    # different quant
MODE=server ./scripts/try.sh     # OpenAI-compatible API on :8080
NGL=0 ./scripts/try.sh           # CPU-only
```

> **Naming note:** "HeavyD-9B" is the local name used in this repo's docs. The actual downloadable weights live upstream at [`empero-ai/Qwythos-9B-Claude-Mythos-5-1M-GGUF`](https://huggingface.co/empero-ai/Qwythos-9B-Claude-Mythos-5-1M-GGUF), so the commands above pull from there. The `hf.co/bkwarmonger-star/verbose-robot` path used elsewhere in this card only works once you re-host the GGUFs under your own Hugging Face repo of that name.

---

## Files

### Text weights

| File | Quant | Size | Notes |
|---|---|---|---|
| `HeavyD-9B-Q4_K_M.gguf` | Q4_K_M | 5.24 GiB / 5.63 GB | **recommended default** — smallest practical quant with good quality |
| `HeavyD-9B-Q5_K_M.gguf` | Q5_K_M | 6.02 GiB / 6.47 GB | balanced quality / size |
| `HeavyD-9B-Q6_K.gguf` | Q6_K | 6.85 GiB / 7.36 GB | high quality |
| `HeavyD-9B-Q8_0.gguf` | Q8_0 | 8.87 GiB / 9.53 GB | near-lossless |
| `HeavyD-9B-BF16.gguf` | BF16 | 16.69 GiB / 17.92 GB | full precision conversion base |

If you don't know which to pick, **Q4_K_M is the right starting point**.

### MTP-enabled text weights

These include a Qwen3.5-compatible MTP head inside the GGUF. Use them with llama.cpp builds that support MTP draft speculation (`--spec-type draft-mtp`).

| File | Quant | Size | Notes |
|---|---|---|---|
| `HeavyD-9B-MTP-Q4_K_M.gguf` | Q4_K_M + MTP | 5.48 GiB / 5.89 GB | **recommended MTP default** |
| `HeavyD-9B-MTP-Q5_K_M.gguf` | Q5_K_M + MTP | 6.26 GiB / 6.73 GB | balanced quality / size |
| `HeavyD-9B-MTP-Q6_K.gguf` | Q6_K + MTP | 7.09 GiB / 7.62 GB | high quality |
| `HeavyD-9B-MTP-Q8_0.gguf` | Q8_0 + MTP | 9.11 GiB / 9.79 GB | near-lossless |
| `HeavyD-9B-MTP-BF16.gguf` | BF16 + MTP | 17.14 GiB / 18.41 GB | full precision conversion base |

### Vision projector — for image input

| File | Size | Notes |
|---|---|---|
| `mmproj-HeavyD-9B-F16.gguf` | 0.86 GiB / 0.92 GB | CLIP-style vision encoder + projector; **required for images**, pairs with any text quant above |

The vision tower is inherited unchanged from the Qwen3.5-9B base (fine-tuning was text-only), so vision behavior matches base Qwen3.5-9B. The mmproj is interchangeable with any community-built Qwen3.5-9B `mmproj-*.gguf`.

---

## Quick start

### llama.cpp (`llama-cli`)

```bash
llama-cli \
  -m HeavyD-9B-Q4_K_M.gguf \
  -p "Explain how a B-tree index speeds up range queries in a relational database." \
  -n 8192 \
  --temp 0.6 --top-p 0.95 --top-k 20 --repeat-penalty 1.05 \
  -c 16384
```

### Ollama

```bash
ollama run hf.co/bkwarmonger-star/verbose-robot:Q4_K_M
```

### LM Studio / jan / KoboldCpp

Drop any `.gguf` file into your runtime's model directory. HeavyD uses the standard Qwen3.5 chat template; modern GGUF runtimes load it automatically from the file.

### llama.cpp with MTP draft speculation

```bash
llama-server \
  -m HeavyD-9B-MTP-Q4_K_M.gguf \
  --spec-type draft-mtp \
  --spec-draft-n-max 6 \
  -c 16384 --port 8080
```

MTP support requires a recent llama.cpp build. If your runtime does not support MTP yet, use the normal text files above.

---

## Vision (image input)

Download both a text quant and the `mmproj-*.gguf` file, then run with llama.cpp's multimodal CLI or server.

### llama.cpp (`llama-mtmd-cli`)

```bash
llama-mtmd-cli \
  -m HeavyD-9B-Q4_K_M.gguf \
  --mmproj mmproj-HeavyD-9B-F16.gguf \
  --image ./photo.jpg \
  -p "Describe this image in detail." \
  --temp 0.6 --top-p 0.95 --top-k 20 \
  -c 16384
```

### llama.cpp server (OpenAI-compatible API with images)

```bash
llama-server \
  -m HeavyD-9B-Q4_K_M.gguf \
  --mmproj mmproj-HeavyD-9B-F16.gguf \
  -c 16384 --port 8080
```

Then POST to `/v1/chat/completions` with an image URL or base64 payload — the standard OpenAI vision API shape works.

### LM Studio

Load the text quant; LM Studio detects the matching `mmproj-*.gguf` in the same folder and enables the image-attach button automatically.

**Note:** the fine-tune was text-only — the vision tower was not trained or evaluated as part of this release, so image-grounded behavior inherits base Qwen3.5-9B. If your application is primarily vision-driven, validate on your own use case first.

---

## Sampling recommendations

HeavyD is a reasoning model — every response opens with a `<think>...</think>` block before the final answer. Use these settings as defaults:

| Parameter | Value |
|---|---|
| `temperature` | 0.6 |
| `top_p` | 0.95 |
| `top_k` | 20 |
| `repeat_penalty` | 1.05 |
| `max_new_tokens` | 16384 (room for `<think>` + answer) |

These match Qwen3.5's official thinking-mode recommendations. Avoid greedy decoding and very-low-temperature sampling (T ≤ 0.3) — both can cause repetition loops on long reasoning generations.

---

## Long context (1M tokens)

The GGUFs ship with YaRN rope-scaling baked in for a 1,048,576-token context window (4× extension over the 262k native).

To use the full 1M window in `llama-cli`, set `-c 1010000` (or any length up to that). For shorter prompts, lower `-c` to reduce KV-cache memory — at default settings llama.cpp will autosize.

A single H100/H200-class GPU comfortably handles 256k–512k; the full 1M typically needs tensor-parallel multi-GPU or aggressive KV-cache offload.

---

## Limitations

- **Reasoning model.** Every answer opens with a `<think>` block; allow generous `max_new_tokens` and parse/strip `<think>...</think>` for end users.
- **Use recommended sampling.** Greedy / very-low-temp can cause repetition loops.
- **Verify specifics.** Like all closed-book LLMs in this weight class, HeavyD can over-commit to specific identifiers it isn't certain about. Pair with retrieval or function calling when factual precision matters — the model uses tools cleanly when offered them.
- **Vision is unevaluated** in this release (text-only fine-tune); validate before relying on it.

---

## Provenance & licensing

Weights are released under **Apache-2.0**, inherited from the Qwen3.5-9B base. Shared for research and experimentation, as-is.

- Base model: [Qwen3.5-9B](https://huggingface.co/Qwen/Qwen3.5-9B) (Alibaba Qwen team)
- Quantization: [llama.cpp](https://github.com/ggml-org/llama.cpp) (ggml-org)
- Vision projector (`mmproj`): inherited from Qwen3.5-9B (vision tower unchanged)
