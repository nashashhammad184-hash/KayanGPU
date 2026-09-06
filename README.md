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

## إعادة البناء على RTX 5090

اتبع هذا الترتيب بالضبط عند تجهيز خادم RTX 5090 جديد:

1. إنشاء خادم RTX 5090 (32GB VRAM) لدى مزود الاستضافة.
2. استنساخ المستودع:
       git clone https://github.com/nashashhammad184-hash/KayanGPU.git
       cd KayanGPU
3. إنشاء ملف البيئة:
       cp .env.example .env
       (ثم تعبئة القيم الحقيقية داخل .env يدوياً — لا تُرفع هذه القيم أبداً لـ Git)
4. تشغيل setup.sh:
       ./setup.sh
   (سيتوقف تلقائياً إذا لم يكن الكرت المكتشف RTX 5090 فعلياً — هذا سلوك مقصود)
5. تشغيل verify.sh للتأكد من جاهزية كل مكوّن:
       ./verify.sh
6. تثبيت النماذج المطلوبة يدوياً حسب docs/MODELS.md (لا تُنزَّل تلقائياً).
7. اختبار HunyuanVideo-1.5 بمقطع قصير جداً للتأكد من عدم تجاوز حدود VRAM (راجع docs/RTX5090.md).
8. اختبار Worker API محلياً (طلب تجريبي بسيط قبل أي ربط خارجي).
9. ربط Worker مع Nashash (تحديث نقطة الاتصال بدل Replicate في artifacts/api-server/src/routes/lipsync.ts، كمهمة منفصلة).
10. تشغيل اختبار إنتاج كامل واحد فقط للتأكد من سلامة السلسلة كاملة (توليد فيديو → Lip Sync → دمج FFmpeg).
