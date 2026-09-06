تنبيه أمني قبل تفعيل الخدمة:

- الخدمة تعمل بمستخدم ubuntu وليس root.
- Worker يجب أن يستمع على 127.0.0.1 فقط (localhost) وليس 0.0.0.0، ويُكشف للخارج فقط عبر reverse proxy مضبوط بمصادقة (GPU_WORKER_SECRET من .env)، وليس مباشرة.
- ComfyUI (إن استُخدم) يجب أن يبقى مربوطاً على 127.0.0.1 فقط ولا يُفتح على الشبكة العامة إطلاقاً.
- ممنوع أن يوفر server.py أي endpoint ينفذ shell commands أو eval على أي مدخل قادم من API.
- الخدمة لا تُفعَّل تلقائياً بهذا الملف وحده. للتفعيل يدوياً بعد جهوزية server.py فعلياً:
    sudo cp systemd/kayangpu-worker.service /etc/systemd/system/
    sudo systemctl daemon-reload
    sudo systemctl enable kayangpu-worker
    sudo systemctl start kayangpu-worker
- لإيقافها:
    sudo systemctl stop kayangpu-worker
    sudo systemctl disable kayangpu-worker
