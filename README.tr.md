# EPS Finder

[English](README.md) · [Türkçe](README.tr.md) · [Deutsch](README.de.md) · [Français](README.fr.md) · [Español](README.es.md)

Finder’da EPS küçük resimleri ve boşluk tuşuyla Hızlı Bakış önizlemesi sağlayan macOS uygulaması.

**Universal 2:** Intel (`x86_64`) ve Apple Silicon (`arm64`). **macOS 13 veya sonrası.** Ghostscript uygulamaya dahildir; kurulan Mac’te Homebrew, Python, Illustrator veya Rosetta gerekmez.

Uygulama arayüzü, hata mesajları ve kurulum sayfaları Türkçe, İngilizce, Almanca, Fransızca ve İspanyolca sunulur. macOS dil tercihlerinize göre otomatik seçim yapar; desteklenen bir dil bulunamazsa İngilizce kullanılır.

1.3.1 sürümü yeni EPS simgesini içerir, temizlik sırasında eski `1.0` kopyalarını tanır ve güncellemeden sonra küçük resim hizmetini yenileyerek Finder’ın eski uzantı yolunu kullanmasını önler. [Simge kaynağı ve üretim istemi](assets/ICON.md) depoya dahildir.

## Kurulum

1. [Releases sayfasından](https://github.com/enesdigital/eps-finder/releases/latest) `EPS-Finder-1.3.1-universal-unsigned.pkg` dosyasını indirin. Intel ve Apple Silicon için aynı paket kullanılır.
2. `.pkg` dosyasını açıp kurulum adımlarını izleyin. Uygulama `/Applications/EPS Finder.app` konumuna kurulur; yönetici onayı gerekir.
3. Uygulamayı bir kez açın. **Örnek dosyayı göster** düğmesi, paketteki örnek EPS’yi Finder’da seçer.

## Kullanım

Finder’da bir `.eps` dosyası seçip **boşluk tuşuna** basın. Simge görünümünde dosyanın küçük resmi de üretilir. Küçük resimler için Finder’ın görünüm seçeneklerinde **Simge önizlemesini göster / Show icon preview** seçeneği açık olmalı.

Kurulum, oturumu açık kullanıcının Quick Look uzantılarını kaydeder. Önizleme görünmezse uygulamayı bir kez açın ve Sistem Ayarları’ndaki **Uzantılar / Hızlı Bakış** bölümünde iki EPS Finder uzantısını etkinleştirin. Diğer kullanıcı hesaplarında da ilk açılış gerekebilir.

Bu sürüm **Developer ID ile imzalanmamıştır ve Apple notarizasyonu içermez**. macOS paketi açmak için kullanıcı onayı isteyebilir. Genel dağıtım için imzalama ve notarizasyon ayrı bir adımdır.

## Güncellemeler

EPS Finder her açıldığında GitHub’daki yeni kararlı sürümü kontrol eder. **EPS Finder açıldığında güncellemeleri otomatik kontrol et** seçeneğini kapatabilir veya uygulama açıkken **Güncellemeleri Kontrol Et** düğmesini kullanabilirsiniz.

Yeni sürüm varsa **İndir ve Kur…** düğmesine basın. Uygulama bu depodaki universal paketi indirir, boyutunu ve GitHub’ın sağladığı SHA-256 değerini doğrular, ardından macOS kurulum ekranını açar. Eski işlem çalışmaya devam etmesin diye kurulum ekranı açılınca EPS Finder kapanır. Yönetici onayıyla kurulumu tamamlayıp EPS Finder’ı yeniden açın. Elle indirmek için **Sürüm Notları** düğmesini kullanabilirsiniz.

1.2.0 ve önceki sürümlerde bu özellik yoktur; önce Releases sayfasından 1.3.1 sürümünü bir kez kurun. Kurulumdan sonra EPS Finder macOS giriş öğesi olarak kaydedilir; her oturum açılışında başlar ve güncellemeleri kontrol eder. **Oturum açıldığında EPS Finder’ı başlat** seçeneğini kapatabilir veya Sistem Ayarları → Genel → Giriş Öğeleri bölümünden yönetebilirsiniz. macOS’ta kapatılan ayara uyulur. Ayrı bir arka plan servisi kurulmaz. Yalnızca uygulama GitHub’a ve indirme sunucularına bağlanır. EPS dosyaları yüklenmez, Quick Look uzantıları ağ izni almaz.

Paket imzasızdır ve Apple notarizasyonu içermez. SHA-256 indirme bütünlüğünü doğrular; Developer ID imzası veya macOS güvenlik onayı yerine geçmez. Eksik veya eşleşmeyen indirmeler silinir. Ağ hatası ya da GitHub istek sınırı durumunda daha sonra yeniden deneyebilirsiniz.

Elle kurulumda ve uygulama içinden güncellemede `/Applications/EPS Finder.app` yenisiyle değiştirilir. `/Applications` ve oturumu açık kullanıcının `~/Applications` klasörlerindeki aynı uygulama kimliğine sahip eski sürümler Çöp’e taşınır. Diğer kullanıcılar yeni uygulamayı açtığında kendi eski kopyaları da kontrol edilir. Eşit/yeni sürümler, başka uygulamalar, sembolik bağlantılar ve EPS belgeleri korunur. Bu standart klasörler dışındaki kopyalar taranmaz. Taşınamayan bir kopya varsa uygulama elle temizlenmesi gerektiğini bildirir.

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

Derleme ayrıca beş dilde gerçek macOS kaynak seçimini, uygulama ve uzantı adlarını, hata mesajlarını, bölgesel dil kodlarını, tercih sırasını ve İngilizceye dönüşü her iki mimaride test eder. Çeviriler `localizations/*.json` dosyalarındadır; derleme standart `.lproj` kaynaklarını üretir.

`build.py`, hem arm64 hem x86_64 kodunu çalıştırarak ASCII ve DOS binary EPS, çizim alanına kırpma, Türkçe/yüzde işaretli dosya yolları, kaynak bütünlüğü, geçersiz dosya, ilgisiz dosya okumasının engellenmesi, zaman aşımı ve sonrasında toparlanmayı sınar. Bu Mac’te Intel kodu Rosetta altında çalıştırılır; fiziksel Intel Mac testi ayrıca yapılmalıdır.

Kurulumdan sonra gerçek Quick Look servisi ile Retina küçük resim testi:

```sh
build/app/check-finder "$PWD/tests/EPS-Test.eps" /private/tmp/eps-finder-thumbnail.png
```

Bu görsel kontrol paketteki koyu zeminli örneğin doğru boyutta ve ortalanmış çizildiğini sınar. Desteklenen en eski macOS sürümünde, fiziksel Intel donanımında ve yönetici onayı gerektiren tam kurulumda test henüz yapılmadı.

## Lisans

AGPL-3.0-or-later; tam metin [LICENSE](LICENSE) dosyasında. Ghostscript ve derleme uyarlaması [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) içinde açıklanır. İkili paketle birlikte oluşturulan kaynak ZIP’i de paylaşın.

[Releases](https://github.com/enesdigital/eps-finder/releases/latest) bölümünde kurulum paketi, tam Ghostscript kaynaklarını içeren kaynak ZIP’i ve `SHA256SUMS` dosyası bulunur. ZIP adı `EPS-Finder-1.3.1-source.zip` şeklindedir; GitHub’ın otomatik oluşturduğu “Source code” arşivinden farklı olarak Ghostscript kaynak arşivini de içerir.

Apple belgeleri: [Universal macOS binary](https://developer.apple.com/documentation/apple-silicon/building-a-universal-macos-binary), [Quick Look UI](https://developer.apple.com/documentation/quicklookui), [notarizasyon](https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution).
