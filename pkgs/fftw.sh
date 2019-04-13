curl -SL http://www.fftw.org/fftw-3.3.8.tar.gz \
    | tar xzf - \
    && cd fftw-3.3.8 \
    && CC="@CC@" CFLAGS="@CFLAGS@" ./configure --enable-threads @CROSS@ --prefix="@AUX_PREFIX@" \
    && make -j @MAKEJ@ && make install \
    && cd .. \
    && rm -rf fftw*
