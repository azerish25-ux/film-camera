package v3;

import com.dwsh.super16.FrameMode;

/* JADX INFO: loaded from: classes.dex */
public abstract /* synthetic */ class k0 {

    /* JADX INFO: renamed from: a, reason: collision with root package name */
    public static final /* synthetic */ int[] f32083a;

    static {
        int[] iArr = new int[FrameMode.values().length];
        try {
            iArr[FrameMode.FILM_SUPER16MM_RAW.ordinal()] = 1;
        } catch (NoSuchFieldError unused) {
        }
        try {
            iArr[FrameMode.FILM_16MM_RAW.ordinal()] = 2;
        } catch (NoSuchFieldError unused2) {
        }
        try {
            iArr[FrameMode.FILM_8MM_RAW.ordinal()] = 3;
        } catch (NoSuchFieldError unused3) {
        }
        try {
            iArr[FrameMode.FILM_SUPER16MM_RAW2.ordinal()] = 4;
        } catch (NoSuchFieldError unused4) {
        }
        try {
            iArr[FrameMode.FILM_SUPER16_BOLEX.ordinal()] = 5;
        } catch (NoSuchFieldError unused5) {
        }
        try {
            iArr[FrameMode.FILM_SUPER8_BEAULIEU.ordinal()] = 6;
        } catch (NoSuchFieldError unused6) {
        }
        try {
            iArr[FrameMode.FILM_16MM_KIEV16U.ordinal()] = 7;
        } catch (NoSuchFieldError unused7) {
        }
        f32083a = iArr;
    }
}
