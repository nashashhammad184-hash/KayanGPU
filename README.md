# KayanGPU Worker

## الوظيفة
GPU Worker خاص بمشروع Nashash/Kayan Studio، يستبدل الاعتماد على Replicate بتشغيل توليد الفيديو، Lip Sync، وLivePortrait محلياً على كرت شاشة مستأجر (RTX 5090 - 32GB VRAM).

## تشغيل Worker
    source venv/bin/activate
    python server.py

## فحص GPU
    bash scripts/gpu_preflight.sh

## فحص FFmpeg
    ffmpeg -version

## تشغيل الاختبارات
    python test_ffmpeg.py
    python test_hunyuan.py

## إيقاف Worker
    sudo systemctl stop kayangpu-worker
    (أو Ctrl+C إذا يعمل مباشرة في الطرفية)

## إعادة البناء على RTX 5090
1. استأجر خادم بكرت RTX 5090 (32GB VRAM).
2. انسخ مجلد KayanGPU هذا بالكامل إلى الخادم الجديد.
3. أنشئ venv جديد وثبّت المتطلبات: pip install -r requirements.txt
4. انسخ .env.example إلى .env واملأ القيم الحقيقية.
5. شغّل scripts/gpu_preflight.sh للتأكد من جاهزية الكرت وCUDA وPyTorch وFFmpeg.
6. شغّل Worker.
