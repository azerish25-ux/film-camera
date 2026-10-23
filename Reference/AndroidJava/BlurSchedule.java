package j4;

import android.opengl.GLES20;
import android.util.Size;
import com.dwsh.super16.FrameMode;
import java.util.List;
import java.util.Map;

/* JADX INFO: loaded from: classes.dex */
public abstract class e {

    /* JADX INFO: renamed from: a, reason: collision with root package name */
    public static final List f24856a = j5.o.G(y7.r.f33936a, j5.o.F(0), j5.o.G(0, 0), j5.o.G(0, 1), j5.o.G(0, 1, 1), j5.o.G(0, 1, 2), j5.o.G(0, 1, 1, 2), j5.o.G(0, 1, 2, 3), j5.o.G(0, 1, 2, 2, 3), j5.o.G(0, 1, 2, 3, 4), j5.o.G(0, 1, 2, 3, 3, 4), j5.o.G(0, 1, 2, 3, 4, 5), j5.o.G(0, 1, 2, 3, 4, 4, 5), j5.o.G(0, 1, 2, 3, 4, 5, 6), j5.o.G(0, 1, 2, 3, 4, 5, 5, 6), j5.o.G(0, 1, 2, 3, 4, 5, 6, 7), j5.o.G(0, 1, 2, 3, 4, 5, 7, 8), j5.o.G(0, 1, 2, 3, 4, 5, 7, 8, 9), j5.o.G(0, 1, 2, 3, 4, 5, 7, 8, 8, 9), j5.o.G(0, 1, 2, 3, 4, 5, 7, 8, 9, 10));

    /* JADX INFO: renamed from: b, reason: collision with root package name */
    public static final Map f24857b = y7.x.y0(new x7.f(FrameMode.FILM_SUPER16MM_RAW, Float.valueOf(0.11f)), new x7.f(FrameMode.FILM_16MM_RAW, Float.valueOf(0.15f)), new x7.f(FrameMode.FILM_8MM_RAW, Float.valueOf(0.16f)), new x7.f(FrameMode.FILM_16X9, Float.valueOf(0.0f)), new x7.f(FrameMode.FILM_4X3, Float.valueOf(0.0f)), new x7.f(FrameMode.FILM_2_39X1, Float.valueOf(0.0f)), new x7.f(FrameMode.FILM_SUPER16MM_FRAME, Float.valueOf(0.0f)), new x7.f(FrameMode.FILM_SUPER16MM_RAW2, Float.valueOf(0.15f)), new x7.f(FrameMode.FILM_SUPER16_BOLEX, Float.valueOf(0.16f)), new x7.f(FrameMode.FILM_SUPER8_BEAULIEU, Float.valueOf(0.0f)), new x7.f(FrameMode.FILM_16MM_KIEV16U, Float.valueOf(0.0f)));

    public static final void a(n2.e eVar, int i6, int i10, int i11, Size size, float f10, FrameMode frameMode, float f11) {
        GLES20.glBindFramebuffer(36009, i10);
        c6.a.j("glFramebufferTexture2D");
        GLES20.glActiveTexture(33984);
        GLES20.glBindTexture(3553, i11);
        eVar.l(i6, 0, "blurTempTexture");
        eVar.m("blurResInv", i6, 1.0f / size.getWidth(), 1.0f / size.getHeight());
        eVar.j("blurOffset", i6, f10);
        Float f12 = (Float) f24857b.get(frameMode);
        eVar.j("blurFramePadding", i6, (f12 != null ? f12.floatValue() : 0.0f) - f11);
        GLES20.glDrawArrays(5, 0, 4);
        c6.a.j("glDrawArrays");
        GLES20.glFlush();
    }
}
