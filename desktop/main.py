"""WhisperSub — GUI desktop (Windows / Linux / macOS).
Tách phụ đề tự động bằng OpenAI Whisper + model fine-tune Hugging Face.
"""
import os
import queue
import threading
import tkinter as tk
from tkinter import filedialog, messagebox, ttk

import transcriber
from models import ALL_MODEL_KEYS, HF_MODELS, LANGUAGES, OFFICIAL_MODELS, SUPPORTED_MEDIA
from subtitles import EXPORTERS

APP_TITLE = "WhisperSub — AI Subtitle Generator"


class App(tk.Tk):
    def __init__(self):
        super().__init__()
        transcriber.setup_ffmpeg_path()
        self.title(APP_TITLE)
        self.geometry("720x560")
        self.minsize(640, 500)
        self.log_queue = queue.Queue()
        self.worker = None
        self._build_ui()
        self.after(100, self._poll_log)

    # ------------------------------------------------------------------ UI
    def _build_ui(self):
        pad = {"padx": 10, "pady": 5}
        frm = ttk.Frame(self)
        frm.pack(fill="both", expand=True)

        # File input
        row = ttk.Frame(frm); row.pack(fill="x", **pad)
        ttk.Label(row, text="File audio/video:").pack(side="left")
        self.file_var = tk.StringVar()
        ttk.Entry(row, textvariable=self.file_var).pack(side="left", fill="x", expand=True, padx=6)
        ttk.Button(row, text="Chọn file...", command=self._pick_file).pack(side="left")

        # Model
        row = ttk.Frame(frm); row.pack(fill="x", **pad)
        ttk.Label(row, text="Model Whisper:").pack(side="left")
        self.model_var = tk.StringVar(value="small")
        model_cb = ttk.Combobox(row, textvariable=self.model_var, values=ALL_MODEL_KEYS, state="readonly", width=32)
        model_cb.pack(side="left", padx=6)
        ttk.Label(row, text="(model fine-tune sẽ tải từ Hugging Face)").pack(side="left")

        # Device CPU/GPU
        row = ttk.Frame(frm); row.pack(fill="x", **pad)
        ttk.Label(row, text="Chạy bằng:").pack(side="left")
        self.device_var = tk.StringVar(value="cpu")
        ttk.Radiobutton(row, text="CPU", variable=self.device_var, value="cpu").pack(side="left", padx=6)
        self.gpu_radio = ttk.Radiobutton(row, text="GPU (CUDA)", variable=self.device_var, value="cuda")
        self.gpu_radio.pack(side="left")
        if transcriber.gpu_available():
            self.device_var.set("cuda")
            ttk.Label(row, text="✅ Phát hiện NVIDIA GPU").pack(side="left", padx=6)
        else:
            self.gpu_radio.state(["disabled"])
            ttk.Label(row, text="⚠️ Không có GPU CUDA — chỉ chạy CPU").pack(side="left", padx=6)

        # Language + output format
        row = ttk.Frame(frm); row.pack(fill="x", **pad)
        ttk.Label(row, text="Ngôn ngữ audio:").pack(side="left")
        self.lang_var = tk.StringVar(value=list(LANGUAGES.keys())[0])
        ttk.Combobox(row, textvariable=self.lang_var, values=list(LANGUAGES.keys()), state="readonly", width=24).pack(side="left", padx=6)
        ttk.Label(row, text="Xuất:").pack(side="left", padx=(12, 0))
        self.fmt_var = tk.StringVar(value="srt")
        ttk.Combobox(row, textvariable=self.fmt_var, values=list(EXPORTERS.keys()), state="readonly", width=6).pack(side="left", padx=6)

        # Start button + progress
        row = ttk.Frame(frm); row.pack(fill="x", **pad)
        self.start_btn = ttk.Button(row, text="▶  Tách phụ đề", command=self._start)
        self.start_btn.pack(side="left")
        self.progress = ttk.Progressbar(row, mode="indeterminate")
        self.progress.pack(side="left", fill="x", expand=True, padx=10)

        # Log
        self.log_text = tk.Text(frm, height=16, state="disabled", wrap="word")
        self.log_text.pack(fill="both", expand=True, padx=10, pady=(5, 10))
        self._log("Sẵn sàng. Chọn file mp3/mp4, model, CPU/GPU, ngôn ngữ rồi bấm 'Tách phụ đề'.")
        self._log(f"Model sẽ được tải về: {transcriber.models_dir()}")

    # ------------------------------------------------------------- actions
    def _pick_file(self):
        path = filedialog.askopenfilename(title="Chọn file audio/video", filetypes=SUPPORTED_MEDIA)
        if path:
            self.file_var.set(path)

    def _start(self):
        file_path = self.file_var.get().strip()
        if not file_path or not os.path.isfile(file_path):
            messagebox.showwarning(APP_TITLE, "Chọn file audio/video hợp lệ đã nhé!")
            return
        if self.worker and self.worker.is_alive():
            messagebox.showinfo(APP_TITLE, "Đang xử lý rồi, đợi xong đã.")
            return

        model_key = self.model_var.get()
        device = self.device_var.get()
        language = LANGUAGES[self.lang_var.get()]
        fmt = self.fmt_var.get()

        self.start_btn.state(["disabled"])
        self.progress.start(12)
        self.worker = threading.Thread(
            target=self._run, args=(file_path, model_key, device, language, fmt), daemon=True
        )
        self.worker.start()

    def _run(self, file_path, model_key, device, language, fmt):
        try:
            backend = "openai-whisper chính chủ" if model_key in OFFICIAL_MODELS else f"Hugging Face ({HF_MODELS[model_key]})"
            self.log_queue.put(f"\u25b6 Bắt đầu | model={model_key} | backend={backend} | device={device} | lang={language or 'auto'}")
            segments, detected = transcriber.transcribe(
                file_path, model_key, device=device, language=language, log=self.log_queue.put
            )
            out_path = os.path.splitext(file_path)[0] + "." + fmt
            with open(out_path, "w", encoding="utf-8") as f:
                f.write(EXPORTERS[fmt](segments))
            self.log_queue.put(f"\u2705 Ngôn ngữ nhận diện: {detected} | {len(segments)} segment")
            self.log_queue.put(f"\u2705 Đã lưu phụ đề: {out_path}")
        except Exception as exc:  # noqa: BLE001
            self.log_queue.put(f"\u274c Lỗi: {exc}")
        finally:
            self.log_queue.put("__DONE__")

    # ---------------------------------------------------------------- log
    def _log(self, msg):
        self.log_text.configure(state="normal")
        self.log_text.insert("end", msg + "\n")
        self.log_text.see("end")
        self.log_text.configure(state="disabled")

    def _poll_log(self):
        try:
            while True:
                msg = self.log_queue.get_nowait()
                if msg == "__DONE__":
                    self.progress.stop()
                    self.start_btn.state(["!disabled"])
                else:
                    self._log(msg)
        except queue.Empty:
            pass
        self.after(100, self._poll_log)


if __name__ == "__main__":
    App().mainloop()
