package j4;

import com.dwsh.super16.FrameMode;

/* JADX INFO: loaded from: classes.dex */
public abstract /* synthetic */ class k {

    /* JADX INFO: renamed from: a, reason: collision with root package name */
    public static final /* synthetic */ int[] f24878a;

    static {
        int[] iArr = new int[FrameMode.values().length];
        try {
            iArr[FrameMode.FILM_SUPER16MM_FRAME.ordinal()] = 1;
        } catch (NoSuchFieldError unused) {
        }
        try {
            iArr[FrameMode.FILM_16MM_KIEV16U.ordinal()] = 2;
        } catch (NoSuchFieldError unused2) {
        }
        try {
            iArr[FrameMode.FILM_SUPER16MM_RAW.ordinal()] = 3;
        } catch (NoSuchFieldError unused3) {
        }
        try {
            iArr[FrameMode.FILM_16MM_RAW.ordinal()] = 4;
        } catch (NoSuchFieldError unused4) {
        }
        try {
            iArr[FrameMode.FILM_SUPER16MM_RAW2.ordinal()] = 5;
        } catch (NoSuchFieldError unused5) {
        }
        try {
            iArr[FrameMode.FILM_SUPER16_BOLEX.ordinal()] = 6;
        } catch (NoSuchFieldError unused6) {
        }
        try {
            iArr[FrameMode.FILM_SUPER8_BEAULIEU.ordinal()] = 7;
        } catch (NoSuchFieldError unused7) {
        }
        try {
            iArr[FrameMode.FILM_8MM_RAW.ordinal()] = 8;
        } catch (NoSuchFieldError unused8) {
        }
        try {
            iArr[FrameMode.NONE.ordinal()] = 9;
        } catch (NoSuchFieldError unused9) {
        }
        try {
            iArr[FrameMode.FILM_16X9.ordinal()] = 10;
        } catch (NoSuchFieldError unused10) {
        }
        try {
            iArr[FrameMode.FILM_4X3.ordinal()] = 11;
        } catch (NoSuchFieldError unused11) {
        }
        try {
            iArr[FrameMode.FILM_2_39X1.ordinal()] = 12;
        } catch (NoSuchFieldError unused12) {
        }
        f24878a = iArr;
    }
}
