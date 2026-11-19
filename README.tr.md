# EPS Finder

[English](README.md) · [Türkçe](README.tr.md) · [Deutsch](README.de.md) · [Français](README.fr.md) · [Español](README.es.md)

Finder’da EPS küçük resimleri ve boşluk tuşuyla Hızlı Bakış önizlemesi sağlayan macOS uygulaması.

**Universal 2:** Intel (`x86_64`) ve Apple Silicon (`arm64`). **macOS 13 veya sonrası.** Ghostscript uygulamaya dahildir; kurulan Mac’te Homebrew, Python, Illustrator veya Rosetta gerekmez.

Uygulama arayüzü, hata mesajları ve kurulum sayfaları Türkçe, İngilizce, Almanca, Fransızca ve İspanyolca sunulur. macOS dil tercihlerinize göre otomatik seçim yapar; desteklenen bir dil bulunamazsa İngilizce kullanılır.

1.4.0 sürümü yeni EPS simgesini içerir, temizlik sırasında eski `1.0` kopyalarını tanır ve güncellemeden sonra küçük resim hizmetini yenileyerek Finder’ın eski uzantı yolunu kullanmasını önler. [Simge kaynağı ve üretim istemi](assets/ICON.md) depoya dahildir.

## Kurulum

1. [Releases sayfasından](https://github.com/enesdigital/eps-finder/releases/latest) `EPS-Finder-1.4.0-universal-unsigned.pkg` dosyasını indirin. Intel ve Apple Silicon için aynı paket kullanılır.
2. `.pkg` dosyasını açıp kurulum adımlarını izleyin. Uygulama `/Applications/EPS Finder.app` konumuna kurulur; yönetici onayı gerekir.
3. Uygulamayı bir kez açın. **Örnek dosyayı göster** düğmesi, paketteki örnek EPS’yi Finder’da seçer.

## Kullanım

Finder’da bir `.eps` dosyası seçip **boşluk tuşuna** basın. Simge görünümünde dosyanın küçük resmi de üretilir. Küçük resimler için Finder’ın görünüm seçeneklerinde **Simge önizlemesini göster / Show icon preview** seçeneği açık olmalı.

Kurulum, oturumu açık kullanıcının Quick Look uzantılarını kaydeder. Önizleme görünmezse uygulamayı bir kez açın ve Sistem Ayarları’ndaki **Uzantılar / Hızlı Bakış** bölümünde iki EPS Finder uzantısını etkinleştirin. Diğer kullanıcı hesaplarında da ilk açılış gerekebilir.

Bu sürüm **Developer ID ile imzalanmamıştır ve Apple notarizasyonu içermez**. macOS paketi açmak için kullanıcı onayı isteyebilir. Genel dağıtım için imzalama ve notarizasyon ayrı bir adımdır.

## Güncellemeler

EPS Finder, Sparkle 2.10.1 ile güncellemeleri uygulama içinde indirir, doğrular ve kurar. **Güncellemeleri Kontrol Et**, **Güncellemeyi Yükle**, ardından **Yükle ve Yeniden Başlat** seçeneklerini kullanın. macOS yönetici onayı isteyebilir; kurulum bitince EPS Finder otomatik açılır. İndirilen paketi kendiniz açmanız gerekmez. **Sürüm Notları** GitHub’daki elle indirme sayfasını açar.

Güncelleme listesi ve paket, uygulamaya gömülü açık anahtarla eşleşen geçerli Ed25519 imzaları taşımalıdır. Değiştirilmiş veya imzası geçersiz güncellemeler reddedilir. Yayıncının özel anahtarı macOS Anahtar Zinciri’nde kalır. Bu imzalar Apple Developer ID imzasından ayrıdır: ilk kurulum paketi hâlâ imzasızdır ve notarizasyon içermez.

**1.3.1 veya öncesinden geçiş:** Releases sayfasından 1.4.0’ı bir kez indirip kurun. Eski güncelleyici uzaktan düzeltilemez. Sonraki güncellemeler yeni uygulama içi kurulumla tamamlanır.

Otomatik kontrol her açılışta ve uygulama açıkken belirli aralıklarla çalışır. Kapatmak için **Güncellemeleri otomatik kontrol et** seçeneğini kaldırın; elle kontrol kullanılabilir. Kurulum uygulamayı oturum açılışında başlayacak şekilde kaydeder. EPS Finder’dan veya Sistem Ayarları → Genel → Giriş Öğeleri bölümünden değiştirebilirsiniz. Mevcut tercihler korunur.

Yalnızca uygulama GitHub’a ve indirme sunucularına bağlanır. EPS belgeleri yüklenmez; Quick Look uzantıları ağ izni almaz. Kalıcı bir ayrıcalıklı yardımcı kurulmaz; Sparkle güncelleme kurulurken yönetici yetkilendirmesi ister.

Kurulum `/Applications/EPS Finder.app` kopyasını değiştirir. Aynı uygulama kimliğine sahip eski kopyalar `/Applications` ve oturumdaki kullanıcının `~/Applications` klasöründen Çöp Sepeti’ne taşınır. Eşit/yeni sürümler, başka uygulamalar, sembolik bağlantılar ve EPS dosyaları korunur. Diğer konumlar taranmaz. Temizlik başarısızsa uygulama eski kopyayı elle kaldırmanızı ister.

## Önizleme görünmüyorsa

1. Dosyanın yalnızca bulutta duran bir yer tutucu olmadığını, Mac’e indirildiğini kontrol edin.
2. EPS Finder’ı bir kez açın ve Sistem Ayarları’nda **Uzantılar / Hızlı Bakış** araması yapıp **EPS Finder — Önizleme** ve **EPS Finder — Küçük resimler** uzantılarını etkinleştirin. Ayarın konumu macOS sürümüne göre değişebilir.
3. Küçük resimler için Finder’ın simge önizlemesi seçeneğini kontrol edin. Bozuk veya harici kaynak gerektiren EPS’ler görüntülenemeyebilir.

## İşleyiş ve sınırlar

EPS, Quick Look uzantısının sandbox’ı içinde Ghostscript `SAFER` moduyla geçici PDF’ye çevrilir. İşlem yereldir; kaynak EPS’ye yazılmaz ve geçici dosyalar temizlenir. Quick Look uzantıları ağ erişimi veya geniş dosya erişim izni istemez. Ana uygulama yalnızca güncelleme kontrolü ve indirme için ağa bağlanır.

- Girdi sınırı: 256 MB. Üretilen PDF sınırı: 64 MB.
- İşleme süresi: küçük resim için 8, büyük önizleme için 15 saniye.
- Gömülmemiş fontlar farklı görünebilir; harici kaynak gerektiren EPS’ler işlenemeyebilir.
- Görüntüleme baskı veya renk provası onayı yerine geçmez.

Kaldırmak için `/Applications/EPS Finder.app` dosyasını Çöp’e taşıyın. Daha önce kullanıcı klasörüne kurulmuş bir kopya varsa o kopyayı da kaldırın.

## Derleme

Dağıtım derlemesi için **Apple Silicon Mac, Rosetta 2, Apple Command Line Tools ve Python 3.9+** gerekir. Bu gereksinimler kurulum yapan son kullanıcıya ait değildir.

```sh
python3 build-engine.py
python3 build.py
python3 package.py
```

İlk komut Ghostscript 10.08.0 kaynak arşivini resmi Artifex GitHub sürümünden indirir, sabit SHA-256 ile doğrular, her mimariyi ayrı derler ve `lipo` ile birleştirir. Sonraki komut uygulamayı oluşturur, yerel ad-hoc imza ekler ve iki mimarinin renderer testlerini çalıştırır. Son komut kurulum paketini, tam kaynak arşivini ve SHA-256 listesini `dist/` içine yazar; paketi tekrar açıp içeriğini doğrular.

Varsayılan `build/` ve `dist/` klasörleri Git tarafından yok sayılır. Tam Ghostscript arşivi Git geçmişine eklenmez; dağıtımın kaynak ZIP’ine dahil edilir.

Farklı bir geçici derleme konumu kullanmak için:

```sh
python3 build-engine.py /private/tmp/eps-finder/engine --source-archive /tam/yol/ghostscript-10.08.0.tar.gz
python3 build.py /private/tmp/eps-finder/app /private/tmp/eps-finder/engine
python3 package.py '/private/tmp/eps-finder/app/EPS Finder.app' --source-archive /tam/yol/ghostscript-10.08.0.tar.gz
```

Kaynak ZIP’inden derlerken `--source-archive vendor/ghostscript-10.08.0.tar.gz` seçeneğiyle paketteki arşivi kullanabilirsiniz.

## Doğrulama

Derleme beş dili, bölgesel dil tercihlerini, İngilizceye dönüşü, renderer sınırlarını ve güvenli eski sürüm seçimini iki mimaride test eder. Paketleme, Sparkle yardımcılarının iki mimariyi içermesini ve güncelleme/paket imzalarını doğrular; değiştirilmiş kopyaların reddedildiğini de sınar. Intel kodu Rosetta ile çalıştırılır. Fiziksel Intel, macOS 13 ve gerçek yeniden başlatma testi yapılmamıştır.

Yayınlamak için Anahtar Zinciri’nde `eps-finder` hesabına ait özel güncelleme anahtarı gerekir. Özel anahtarı depoya veya kaynak ZIP’ine eklemeyin. `appcast.xml` dahil `dist/` dosyalarını birlikte yayımlayın. Ayrıntılı derleme ve yayınlama adımları [İngilizce kılavuzdadır](README.md#build).

## Lisans

AGPL-3.0-or-later; tam metin [LICENSE](LICENSE) dosyasında. Ghostscript ve derleme uyarlaması [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) içinde açıklanır. İkili paketle birlikte oluşturulan kaynak ZIP’i de paylaşın.

1.4.0 sürümü Sparkle ile doğrulanan uygulama içi güncellemeleri ekler. [EPS icon](assets/ICON.md).

Apple belgeleri: [Universal macOS binary](https://developer.apple.com/documentation/apple-silicon/building-a-universal-macos-binary), [Quick Look UI](https://developer.apple.com/documentation/quicklookui), [notarizasyon](https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution).

[Sparkle 2.10.1 · MIT · Ed25519 · appcast.xml](README.md#updates)
