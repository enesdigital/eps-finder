# EPS Finder

[Türkçe](README.md) · [English](README.en.md) · [Deutsch](README.de.md) · [Français](README.fr.md) · [Español](README.es.md)

Finder’da EPS küçük resimleri ve boşluk tuşuyla Hızlı Bakış önizlemesi sağlayan macOS uygulaması.

**Universal 2:** Intel (`x86_64`) ve Apple Silicon (`arm64`). **macOS 13 veya sonrası.** Ghostscript uygulamaya dahildir; kurulan Mac’te Homebrew, Python, Illustrator veya Rosetta gerekmez.

## Kurulum

1. [Releases sayfasından](https://github.com/enesdigital/eps-finder/releases/latest) `EPS-Finder-1.1.0-universal-unsigned.pkg` dosyasını indirin. Intel ve Apple Silicon için aynı paket kullanılır.
2. `.pkg` dosyasını açıp kurulum adımlarını izleyin. Uygulama `/Applications/EPS Finder.app` konumuna kurulur; yönetici onayı gerekir.
3. Uygulamayı bir kez açın. **Örnek dosyayı göster** düğmesi, paketteki örnek EPS’yi Finder’da seçer.

## Kullanım

Finder’da bir `.eps` dosyası seçip **boşluk tuşuna** basın. Simge görünümünde dosyanın küçük resmi de üretilir. Küçük resimler için Finder’ın görünüm seçeneklerinde **Simge önizlemesini göster / Show icon preview** seçeneği açık olmalı.

Kurulum, oturumu açık kullanıcının Quick Look uzantılarını kaydeder. Önizleme görünmezse uygulamayı bir kez açın ve Sistem Ayarları’ndaki **Uzantılar / Hızlı Bakış** bölümünde iki EPS Finder uzantısını etkinleştirin. Diğer kullanıcı hesaplarında da ilk açılış gerekebilir.

Bu sürüm **Developer ID ile imzalanmamıştır ve Apple notarizasyonu içermez**. macOS paketi açmak için kullanıcı onayı isteyebilir. Genel dağıtım için imzalama ve notarizasyon ayrı bir adımdır.

## Önizleme görünmüyorsa

1. Dosyanın yalnızca bulutta duran bir yer tutucu olmadığını, Mac’e indirildiğini kontrol edin.
2. EPS Finder’ı bir kez açın ve Sistem Ayarları’nda **Uzantılar / Hızlı Bakış** araması yapıp **EPS Finder — Preview** ve **EPS Finder — Thumbnail** uzantılarını etkinleştirin. Ayarın konumu macOS sürümüne göre değişebilir.
3. Küçük resimler için Finder’ın simge önizlemesi seçeneğini kontrol edin. Bozuk veya harici kaynak gerektiren EPS’ler görüntülenemeyebilir.

## İşleyiş ve sınırlar

EPS, Quick Look uzantısının sandbox’ı içinde Ghostscript `SAFER` moduyla geçici PDF’ye çevrilir. İşlem yereldir; kaynak EPS’ye yazılmaz ve geçici dosyalar temizlenir. Ağ erişimi veya geniş dosya erişim izni istenmez.

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

`build.py`, hem arm64 hem x86_64 kodunu çalıştırarak ASCII ve DOS binary EPS, çizim alanına kırpma, Türkçe/yüzde işaretli dosya yolları, kaynak bütünlüğü, geçersiz dosya, ilgisiz dosya okumasının engellenmesi, zaman aşımı ve sonrasında toparlanmayı sınar. Bu Mac’te Intel kodu Rosetta altında çalıştırılır; fiziksel Intel Mac testi ayrıca yapılmalıdır.

Kurulumdan sonra gerçek Quick Look servisi ile Retina küçük resim testi:

```sh
build/app/check-finder "$PWD/tests/EPS-Test.eps" /private/tmp/eps-finder-thumbnail.png
```

Bu görsel kontrol paketteki koyu zeminli örneğin doğru boyutta ve ortalanmış çizildiğini sınar. Desteklenen en eski macOS sürümünde, fiziksel Intel donanımında ve yönetici onayı gerektiren tam kurulumda test henüz yapılmadı.

## Lisans

AGPL-3.0-or-later; tam metin [LICENSE](LICENSE) dosyasında. Ghostscript ve derleme uyarlaması [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) içinde açıklanır. İkili paketle birlikte oluşturulan kaynak ZIP’i de paylaşın.

[Releases](https://github.com/enesdigital/eps-finder/releases/latest) bölümünde kurulum paketi, tam Ghostscript kaynaklarını içeren kaynak ZIP’i ve `SHA256SUMS` dosyası bulunur. ZIP adı `EPS-Finder-1.1.0-source.zip` şeklindedir; GitHub’ın otomatik oluşturduğu “Source code” arşivinden farklı olarak Ghostscript kaynak arşivini de içerir.

Apple belgeleri: [Universal macOS binary](https://developer.apple.com/documentation/apple-silicon/building-a-universal-macos-binary), [Quick Look UI](https://developer.apple.com/documentation/quicklookui), [notarizasyon](https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution).
