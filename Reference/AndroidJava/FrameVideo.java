// Readability view: decoded string constants; build uses preserved smali.
package v3;

import android.content.Context;
import android.graphics.SurfaceTexture;
import android.media.MediaPlayer;
import android.view.Surface;
import com.dwsh.super16.FrameMode;
import com.google.firebase.crashlytics.FirebaseCrashlytics;
import java.util.ArrayList;
import java.util.List;
import kotlin.NoWhenBranchMatchedException;

/* JADX INFO: loaded from: classes.dex */
public final class w0 implements MediaPlayer.OnPreparedListener, MediaPlayer.OnErrorListener {

    /* JADX INFO: renamed from: d, reason: collision with root package name */
    public static int f32209d;

    /* JADX INFO: renamed from: e, reason: collision with root package name */
    public static boolean f32210e;

    /* JADX INFO: renamed from: a, reason: collision with root package name */
    public final List f32211a;

    /* JADX INFO: renamed from: b, reason: collision with root package name */
    public MediaPlayer f32212b;

    /* JADX INFO: renamed from: c, reason: collision with root package name */
    public Surface f32213c;

    public w0(Context context, SurfaceTexture surfaceTexture, FrameMode frameMode) {
        List listG;
        y4.u0.q(context, "activityContext");
        "lightleaksurfacetexture";
        y4.u0.q(frameMode, "frameMode");
        switch (v0.f32189a[frameMode.ordinal()]) {
            case 1:
                listG = j5.o.G(1, 1, 1, 1, 1, 1, 1);
                break;
            case 2:
                listG = j5.o.G(0, 1, 1, 1, 1, 1, 1);
                break;
            case 3:
                listG = j5.o.G(0, 1, 1, 1, 1, 1, 1);
                break;
            case 4:
                listG = j5.o.G(0, 1, 1, 1, 1, 1, 1);
                break;
            case 5:
                listG = j5.o.G(0, 1, 1, 1, 1, 1, 1);
                break;
            case 6:
                listG = j5.o.G(0, 1, 1, 1, 1, 1, 1);
                break;
            case 7:
                listG = j5.o.G(0, 1, 1, 1, 1, 1, 1);
                break;
            case 8:
                listG = j5.o.G(0, 1, 1, 1, 1, 1, 1);
                break;
            case 9:
                listG = j5.o.G(0, 1, 1, 1, 1, 1, 1);
                break;
            case 10:
                listG = j5.o.G(0, 1, 1, 1, 1, 1, 1);
                break;
            case 11:
                listG = j5.o.G(0, 1, 1, 1, 1, 1, 1);
                break;
            case 12:
                listG = j5.o.G(0, 1, 1, 1, 1, 1, 1);
                break;
            default:
                throw new NoWhenBranchMatchedException();
        }
        this.f32211a = listG;
        String[] strArr = {"fb6de461e7725ac8c6adc93ce40d9be33058f87b", "7279f61845c546ea5a98521a24361e0fd7f1dab8", "ebf7742d8724b91d81f26c099a7b84aafced9c9c", "219d4a1d9955023fb00ee040507bfba392157e26", "a071faf6bfb388993c6db6ead6942ffd89da9334", "917d6d8b0e4a29253b6f0bcd1626c5f7483b1a78", "0a4c51f6cc776d9a4c73e2eb83acf7e777e2b0e5"};
        ArrayList arrayList = new ArrayList();
        int i6 = 0;
        int i10 = 0;
        while (i6 < 7) {
            String str = strArr[i6];
            int i11 = i10 + 1;
            if (((Number) this.f32211a.get(i10)).intValue() == 1) {
                arrayList.add(str);
            }
            i6++;
            i10 = i11;
        }
        MediaPlayer mediaPlayer = new MediaPlayer();
        this.f32212b = mediaPlayer;
        try {
            mediaPlayer.setOnErrorListener(this);
            MediaPlayer mediaPlayer2 = this.f32212b;
            if (mediaPlayer2 != null) {
                mediaPlayer2.setOnPreparedListener(this);
            }
            MediaPlayer mediaPlayer3 = this.f32212b;
            if (mediaPlayer3 != null) {
                m1 m1Var = m1.f32110a;
                StringBuilder sb2 = new StringBuilder();
                sb2.append("0c6c7818c097fa7cc58696d3dd93d3595a750e3a/");
                String str2 = (String) y7.p.g0(f32209d, arrayList);
                if (str2 == null) {
                    f32209d = 0;
                    str2 = (String) arrayList.get(0);
                }
                sb2.append(str2);
                mediaPlayer3.setDataSource(m1Var.d(context, sb2.toString()));
            }
            f32209d = (f32209d + 1) % arrayList.size();
            MediaPlayer mediaPlayer4 = this.f32212b;
            if (mediaPlayer4 != null) {
                mediaPlayer4.setOnCompletionListener(new MediaPlayer.OnCompletionListener() { // from class: v3.u0
                    @Override // android.media.MediaPlayer.OnCompletionListener
                    public final void onCompletion(MediaPlayer mediaPlayer5) {
                        String strE = "this$0";
                        w0 w0Var = this.f32185a;
                        y4.u0.q(w0Var, strE);
                        w0.f32210e = false;
                        j4.p.f24917d1 = false;
                        j4.p.f24918e1 = false;
                        MediaPlayer mediaPlayer6 = w0Var.f32212b;
                        if (mediaPlayer6 != null) {
                            mediaPlayer6.stop();
                        }
                        MediaPlayer mediaPlayer7 = w0Var.f32212b;
                        if (mediaPlayer7 != null) {
                            mediaPlayer7.release();
                        }
                        w0Var.f32212b = null;
                        Surface surface = w0Var.f32213c;
                        if (surface != null) {
                            surface.release();
                        }
                        w0Var.f32213c = null;
                    }
                });
            }
            Surface surface = new Surface(surfaceTexture);
            this.f32213c = surface;
            if (!(surface.isValid()) || gb.m.B(surfaceTexture)) {
                return;
            }
            MediaPlayer mediaPlayer5 = this.f32212b;
            if (mediaPlayer5 != null) {
                mediaPlayer5.setSurface(this.f32213c);
            }
            MediaPlayer mediaPlayer6 = this.f32212b;
            if (mediaPlayer6 != null) {
                mediaPlayer6.prepareAsync();
            }
            j4.p.f24917d1 = true;
            j4.p.f24918e1 = false;
        } catch (Exception e10) {
            FirebaseCrashlytics.getInstance().recordException(e10);
        }
    }

    public final void finalize() {
        MediaPlayer mediaPlayer = this.f32212b;
        if (mediaPlayer != null) {
            mediaPlayer.reset();
        }
        MediaPlayer mediaPlayer2 = this.f32212b;
        if (mediaPlayer2 != null) {
            mediaPlayer2.release();
        }
        this.f32212b = null;
    }

    @Override // android.media.MediaPlayer.OnErrorListener
    public final boolean onError(MediaPlayer mediaPlayer, int i6, int i10) {
        FirebaseCrashlytics.getInstance().recordException(new Exception("LightLeaks onError " + i6 + ' ' + i10));
        return false;
    }

    @Override // android.media.MediaPlayer.OnPreparedListener
    public final void onPrepared(MediaPlayer mediaPlayer) {
        if (mediaPlayer != null) {
            mediaPlayer.start();
        }
        f32210e = true;
    }
}
