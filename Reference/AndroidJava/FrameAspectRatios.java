package o4;

import android.net.Uri;
import android.widget.TextView;
import com.dwsh.super16.FrameMode;
import com.dwsh.super16.R;
import com.dwsh.super16.ui.Super16EditorActivity;
import com.universalvideoview.UniversalMediaController;
import kotlin.coroutines.Continuation;

/* JADX INFO: loaded from: classes.dex */
public final class h5 extends c8.h implements i8.c {

    /* JADX INFO: renamed from: a, reason: collision with root package name */
    public int f28215a;

    /* JADX INFO: renamed from: b, reason: collision with root package name */
    public /* synthetic */ Object f28216b;

    /* JADX INFO: renamed from: c, reason: collision with root package name */
    public final /* synthetic */ Super16EditorActivity f28217c;

    /* JADX WARN: 'super' call moved to the top of the method (can break code semantics) */
    public h5(Super16EditorActivity super16EditorActivity, Continuation continuation) {
        super(2, continuation);
        this.f28217c = super16EditorActivity;
    }

    @Override // c8.a
    public final Continuation create(Object obj, Continuation continuation) {
        h5 h5Var = new h5(this.f28217c, continuation);
        h5Var.f28216b = obj;
        return h5Var;
    }

    @Override // i8.c
    public final Object invoke(Object obj, Object obj2) {
        return ((h5) create((FrameMode) obj, (Continuation) obj2)).invokeSuspend(x7.p.f33227a);
    }

    /* JADX WARN: Unreachable blocks removed: 1, instructions: 1 */
    @Override // c8.a
    public final Object invokeSuspend(Object obj) {
        float f10;
        s3.l lVar;
        b8.a aVar = b8.a.COROUTINE_SUSPENDED;
        int i6 = this.f28215a;
        if (i6 == 0) {
            com.bumptech.glide.c.B(obj);
            FrameMode frameMode = (FrameMode) this.f28216b;
            Super16EditorActivity super16EditorActivity = this.f28217c;
            g4.k kVar = Super16EditorActivity.R0;
            super16EditorActivity.getClass();
            l.e.e(-123059486257256L);
            TextView textView = (TextView) super16EditorActivity.findViewById(R.id.aspect_ratio_label);
            switch (i4.f28227a[frameMode.ordinal()]) {
                case 1:
                    l.e.e(-123055191289960L);
                    textView.setText(R.string.aspect_ratio_label_super16mm_raw);
                    f10 = 1.3333334f;
                    break;
                case 2:
                    l.e.e(-123102435930216L);
                    textView.setText(R.string.aspect_ratio_label_16x9);
                    f10 = 1.7777778f;
                    break;
                case 3:
                    l.e.e(-122638579462248L);
                    textView.setText(R.string.aspect_ratio_label_4x3);
                    f10 = 1.3333334f;
                    break;
                case 4:
                    l.e.e(-122660054298728L);
                    textView.setText(R.string.aspect_ratio_label_2_39x1);
                    f10 = 2.39f;
                    break;
                case 5:
                    l.e.e(-123025126518888L);
                    textView.setText(R.string.aspect_ratio_label_16mm_raw);
                    f10 = 1.3333334f;
                    break;
                case 6:
                    l.e.e(-123132500701288L);
                    textView.setText(R.string.aspect_ratio_label_8mm_raw);
                    f10 = 1.7777778f;
                    break;
                case 7:
                    l.e.e(-122608514691176L);
                    textView.setText(R.string.super16mm_raw_2);
                    f10 = 1.7777778f;
                    break;
                case 8:
                    l.e.e(-122715888873576L);
                    textView.setText(R.string.super16mm_raw_3);
                    f10 = 1.3333334f;
                    break;
                case 9:
                    l.e.e(-122685824102504L);
                    textView.setText(R.string.super16mm_bolex);
                    f10 = 1.7777778f;
                    break;
                case 10:
                    l.e.e(-122793198284904L);
                    textView.setText(R.string.super8mm_beaulieu);
                    f10 = 1.3333334f;
                    break;
                case 11:
                    l.e.e(-122763133513832L);
                    textView.setText(R.string.label_16mm_kiev16u);
                    f10 = 1.3333334f;
                    break;
                default:
                    f10 = 1.0f;
                    break;
            }
            super16EditorActivity.O0 = true;
            c6.a.b0(super16EditorActivity, r3.R);
            super16EditorActivity.f3520v0 = f10;
            w3.k kVar2 = super16EditorActivity.f3509k0;
            if (kVar2 != null) {
                kVar2.f32603k = true;
            }
            j4.l0 l0Var = super16EditorActivity.f3508j0;
            if (l0Var != null) {
                l0Var.D = true;
            }
            w3.k kVar3 = super16EditorActivity.f3509k0;
            if (kVar3 != null) {
                s3.l lVar2 = kVar3.f32597e;
                if ((lVar2 != null && lVar2.d()) && (lVar = kVar3.f32597e) != null) {
                    lVar.e();
                }
            }
            w3.k kVar4 = super16EditorActivity.f3509k0;
            if (kVar4 != null) {
                kVar4.a();
            }
            super16EditorActivity.f3509k0 = null;
            g4.f fVar = super16EditorActivity.f3510l0;
            if (fVar != null) {
                fVar.c();
            }
            super16EditorActivity.f3510l0 = null;
            j4.l0 l0Var2 = super16EditorActivity.f3508j0;
            if (l0Var2 != null) {
                l0Var2.c();
            }
            super16EditorActivity.f3508j0 = null;
            c6.a.b0(super16EditorActivity, r3.S);
            if (!super16EditorActivity.K0) {
                g4.m mVar = super16EditorActivity.f3507i0;
                if (mVar == null) {
                    y4.u0.r0(l.e.e(-122733068742760L));
                    throw null;
                }
                if (mVar == g4.m.IMAGE) {
                    c6.a.b0(super16EditorActivity, r3.T);
                    Uri uriN = super16EditorActivity.N();
                    UniversalMediaController universalMediaController = super16EditorActivity.Q().G;
                    y4.u0.p(universalMediaController, l.e.e(-122823263055976L));
                    super16EditorActivity.f3510l0 = new g4.f(uriN, universalMediaController, new e4.q(9, super16EditorActivity, frameMode), new e5(super16EditorActivity, 1));
                } else {
                    super16EditorActivity.f3509k0 = new w3.k(super16EditorActivity, super16EditorActivity.f3511m0, super16EditorActivity.N());
                    super16EditorActivity.F(frameMode);
                    super16EditorActivity.T();
                    super16EditorActivity.O0 = false;
                }
            }
            v3.w wVar = v3.w.f32190a;
            p4.c cVarH = this.f28217c.M().h();
            this.f28215a = 1;
            if (wVar.b(frameMode, cVarH, this) == aVar) {
                return aVar;
            }
        } else {
            if (i6 != 1) {
                throw new IllegalStateException(l.e.e(-183120308924520L));
            }
            com.bumptech.glide.c.B(obj);
        }
        return x7.p.f33227a;
    }
}
