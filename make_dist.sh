[ -d $PWD/dist/ ] && rm -rf dist/
[ -f site*.deb ] && rm site*.deb

mkdir -p dist/{DEBIAN,usr/bin,usr/share/bash-completion/completions,etc}
cp -r site.conf.d/ dist/etc
cp site.sh dist/usr/bin/site
chmod +x dist/usr/bin/site
cp site-completion.sh dist/usr/share/bash-completion/completions/site

cat > dist/DEBIAN/control << EOF
Package: site
Version: 0.1
Section: admin
Priority: optional
Architecture: all
Maintainer: me <mymail@mail.com>
Description: Add site.
EOF

dpkg-deb --build ./dist site.deb
