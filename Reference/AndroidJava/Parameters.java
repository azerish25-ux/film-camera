// Readability view: decoded string constants; build uses preserved smali.
package h4;

import android.content.SharedPreferences;
import com.dwsh.super16.FrameMode;
import com.dwsh.super16.data.entities.CustomFilterEntity;
import com.dwsh.super16.presets.Preset;
import com.dwsh.super16.ui.Super16EditorActivity;
import com.google.gson.Gson;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;
import java.util.UUID;
import o4.d4;
import o4.z1;
import v3.f1;
import v3.g1;
import v3.h1;
import y4.u0;

/* JADX INFO: loaded from: classes.dex */
public abstract class d {
    public static final f1 A;
    public static final f1 B;
    public static final f1 C;
    public static final ArrayList D;
    public static final ArrayList E;
    public static final a F;
    public static final a G;
    public static final a H;
    public static long I;
    public static final n8.f J;

    /* JADX INFO: renamed from: a, reason: collision with root package name */
    public static final g1 f23894a = new g1(0);

    /* JADX INFO: renamed from: b, reason: collision with root package name */
    public static final g1 f23895b = new g1(0);

    /* JADX INFO: renamed from: c, reason: collision with root package name */
    public static final g1 f23896c = new g1(0);

    /* JADX INFO: renamed from: d, reason: collision with root package name */
    public static final f1 f23897d = new f1(0.0f);

    /* JADX INFO: renamed from: e, reason: collision with root package name */
    public static final g1 f23898e = new g1(6600);

    /* JADX INFO: renamed from: f, reason: collision with root package name */
    public static final g1 f23899f = new g1(0);

    /* JADX INFO: renamed from: g, reason: collision with root package name */
    public static final f1 f23900g = new f1(1.0f);

    /* JADX INFO: renamed from: h, reason: collision with root package name */
    public static final g1 f23901h = new g1(1);

    /* JADX INFO: renamed from: i, reason: collision with root package name */
    public static final f1 f23902i = new f1(0.0f);

    /* JADX INFO: renamed from: j, reason: collision with root package name */
    public static final f1 f23903j = new f1(0.27f);

    /* JADX INFO: renamed from: k, reason: collision with root package name */
    public static final f1 f23904k = new f1(0.3f);

    /* JADX INFO: renamed from: l, reason: collision with root package name */
    public static final f1 f23905l = new f1(0.0f);

    /* JADX INFO: renamed from: m, reason: collision with root package name */
    public static final g1[] f23906m;

    /* JADX INFO: renamed from: n, reason: collision with root package name */
    public static final f1 f23907n;

    /* JADX INFO: renamed from: o, reason: collision with root package name */
    public static final f1 f23908o;

    /* JADX INFO: renamed from: p, reason: collision with root package name */
    public static final g1 f23909p;

    /* JADX INFO: renamed from: q, reason: collision with root package name */
    public static final f1 f23910q;

    /* JADX INFO: renamed from: r, reason: collision with root package name */
    public static final f1 f23911r;

    /* JADX INFO: renamed from: s, reason: collision with root package name */
    public static final f1 f23912s;

    /* JADX INFO: renamed from: t, reason: collision with root package name */
    public static final f1 f23913t;

    /* JADX INFO: renamed from: u, reason: collision with root package name */
    public static final g1 f23914u;

    /* JADX INFO: renamed from: v, reason: collision with root package name */
    public static final f1 f23915v;

    /* JADX INFO: renamed from: w, reason: collision with root package name */
    public static final f1 f23916w;

    /* JADX INFO: renamed from: x, reason: collision with root package name */
    public static final f1 f23917x;

    /* JADX INFO: renamed from: y, reason: collision with root package name */
    public static final f1 f23918y;

    /* JADX INFO: renamed from: z, reason: collision with root package name */
    public static final f1 f23919z;

    /* JADX WARN: Type inference failed for: r2v10, types: [h4.a] */
    /* JADX WARN: Type inference failed for: r2v8, types: [h4.a] */
    /* JADX WARN: Type inference failed for: r2v9, types: [h4.a] */
    static {
        List listD0 = y7.p.D0(new p8.e(0, 255));
        ArrayList arrayList = new ArrayList(y7.m.S(listD0));
        Iterator it = listD0.iterator();
        while (it.hasNext()) {
            arrayList.add(new g1(((Number) it.next()).intValue()));
        }
        g1[] g1VarArr = (g1[]) arrayList.toArray(new g1[0]);
        f23906m = g1VarArr;
        f1 f1Var = new f1(0.0f);
        f23907n = f1Var;
        f1 f1Var2 = new f1(0.9f);
        f23908o = f1Var2;
        g1 g1Var = new g1(95);
        f23909p = g1Var;
        f1 f1Var3 = new f1(0.5f);
        f23910q = f1Var3;
        f1 f1Var4 = new f1(0.0f);
        f23911r = f1Var4;
        f1 f1Var5 = new f1(0.0f);
        f23912s = f1Var5;
        f1 f1Var6 = new f1(0.35f);
        f23913t = f1Var6;
        g1 g1Var2 = new g1(0);
        f23914u = g1Var2;
        f1 f1Var7 = new f1(0.3f);
        f23915v = f1Var7;
        f1 f1Var8 = new f1(0.04f);
        f23916w = f1Var8;
        f1 f1Var9 = new f1(0.0f);
        f23917x = f1Var9;
        f1 f1Var10 = new f1(0.0f);
        f23918y = f1Var10;
        f1 f1Var11 = new f1(0.0f);
        f23919z = f1Var11;
        f1 f1Var12 = new f1(1.0f);
        A = f1Var12;
        f1 f1Var13 = new f1(1.0f);
        B = f1Var13;
        f1 f1Var14 = new f1(0.0f);
        C = f1Var14;
        D = new ArrayList();
        E = new ArrayList();
        final int i6 = 0;
        F = new h1() { // from class: h4.a
            @Override // v3.h1
            public final void a(Number number) {
                switch (i6) {
                    case 0:
                        ((Integer) number).intValue();
                        while (true) {
                            for (d4 d4Var : d.E) {
                                d4Var.getClass();
                                g4.k kVar = Super16EditorActivity.R0;
                                String strE = "this$0";
                                Super16EditorActivity super16EditorActivity = d4Var.f28152a;
                                u0.q(super16EditorActivity, strE);
                                g4.f fVar = super16EditorActivity.f3510l0;
                                if (fVar != null) {
                                    fVar.d(0);
                                }
                            }
                            break;
                        }
                        break;
                    case 1:
                        ((Float) number).floatValue();
                        for (d4 d4Var2 : d.E) {
                            d4Var2.getClass();
                            g4.k kVar2 = Super16EditorActivity.R0;
                            String strE2 = "this$0";
                            Super16EditorActivity super16EditorActivity2 = d4Var2.f28152a;
                            u0.q(super16EditorActivity2, strE2);
                            g4.f fVar2 = super16EditorActivity2.f3510l0;
                            if (fVar2 != null) {
                                fVar2.d(0);
                            }
                        }
                        break;
                    default:
                        ((Integer) number).intValue();
                        Long lValueOf = Long.valueOf(System.nanoTime());
                        if (!(lValueOf.longValue() != 0)) {
                            lValueOf = null;
                        }
                        d.I = lValueOf != null ? lValueOf.longValue() : d.J.i();
                        break;
                }
            }
        };
        final int i10 = 1;
        G = new h1() { // from class: h4.a
            @Override // v3.h1
            public final void a(Number number) {
                switch (i10) {
                    case 0:
                        ((Integer) number).intValue();
                        while (true) {
                            for (d4 d4Var : d.E) {
                                d4Var.getClass();
                                g4.k kVar = Super16EditorActivity.R0;
                                String strE = "this$0";
                                Super16EditorActivity super16EditorActivity = d4Var.f28152a;
                                u0.q(super16EditorActivity, strE);
                                g4.f fVar = super16EditorActivity.f3510l0;
                                if (fVar != null) {
                                    fVar.d(0);
                                }
                            }
                            break;
                        }
                        break;
                    case 1:
                        ((Float) number).floatValue();
                        for (d4 d4Var2 : d.E) {
                            d4Var2.getClass();
                            g4.k kVar2 = Super16EditorActivity.R0;
                            String strE2 = "this$0";
                            Super16EditorActivity super16EditorActivity2 = d4Var2.f28152a;
                            u0.q(super16EditorActivity2, strE2);
                            g4.f fVar2 = super16EditorActivity2.f3510l0;
                            if (fVar2 != null) {
                                fVar2.d(0);
                            }
                        }
                        break;
                    default:
                        ((Integer) number).intValue();
                        Long lValueOf = Long.valueOf(System.nanoTime());
                        if (!(lValueOf.longValue() != 0)) {
                            lValueOf = null;
                        }
                        d.I = lValueOf != null ? lValueOf.longValue() : d.J.i();
                        break;
                }
            }
        };
        final int i11 = 2;
        H = new h1() { // from class: h4.a
            @Override // v3.h1
            public final void a(Number number) {
                switch (i11) {
                    case 0:
                        ((Integer) number).intValue();
                        while (true) {
                            for (d4 d4Var : d.E) {
                                d4Var.getClass();
                                g4.k kVar = Super16EditorActivity.R0;
                                String strE = "this$0";
                                Super16EditorActivity super16EditorActivity = d4Var.f28152a;
                                u0.q(super16EditorActivity, strE);
                                g4.f fVar = super16EditorActivity.f3510l0;
                                if (fVar != null) {
                                    fVar.d(0);
                                }
                            }
                            break;
                        }
                        break;
                    case 1:
                        ((Float) number).floatValue();
                        for (d4 d4Var2 : d.E) {
                            d4Var2.getClass();
                            g4.k kVar2 = Super16EditorActivity.R0;
                            String strE2 = "this$0";
                            Super16EditorActivity super16EditorActivity2 = d4Var2.f28152a;
                            u0.q(super16EditorActivity2, strE2);
                            g4.f fVar2 = super16EditorActivity2.f3510l0;
                            if (fVar2 != null) {
                                fVar2.d(0);
                            }
                        }
                        break;
                    default:
                        ((Integer) number).intValue();
                        Long lValueOf = Long.valueOf(System.nanoTime());
                        if (!(lValueOf.longValue() != 0)) {
                            lValueOf = null;
                        }
                        d.I = lValueOf != null ? lValueOf.longValue() : d.J.i();
                        break;
                }
            }
        };
        J = new n8.f(23242, 0);
        f1Var5.f32004c.add(new b(new j8.u(), 0));
        g1Var2.f32015c.add(new b(new j8.u(), 1));
        f1Var9.f32004c.add(new b(new j8.u(), 2));
        f1Var10.f32004c.add(new b(new j8.u(), 3));
        f1Var11.f32004c.add(new b(new j8.u(), 4));
        List listG = j5.o.G(f23894a, f23895b, f23896c, f23897d, f23898e, f23899f, f23900g, f23901h, f23902i, f23903j, f23904k, f23905l, g1VarArr, f1Var, f1Var2, g1Var, f1Var3, f1Var4, f1Var5, f1Var6, g1Var2, f1Var7, f1Var8, f1Var9, f1Var10, f1Var11, f1Var12, f1Var13, f1Var14);
        ArrayList arrayList2 = new ArrayList();
        for (Object obj : listG) {
            y7.o.W(obj instanceof Object[] ? y7.l.U((Object[]) obj) : j5.o.F(obj), arrayList2);
        }
        for (Object obj2 : arrayList2) {
            if (obj2 instanceof g1) {
                ((g1) obj2).f32015c.add(F);
            } else if (obj2 instanceof f1) {
                ((f1) obj2).f32004c.add(G);
            }
        }
        List listG2 = j5.o.G(f23898e, f23899f, f23906m);
        ArrayList arrayList3 = new ArrayList();
        for (Object obj3 : listG2) {
            y7.o.W(obj3 instanceof Object[] ? y7.l.U((Object[]) obj3) : j5.o.F(obj3), arrayList3);
        }
        for (Object obj4 : arrayList3) {
            if (obj4 instanceof g1) {
                ((g1) obj4).f32015c.add(H);
            }
        }
    }

    public static void a(Preset preset) {
        u0.q(preset, "preset");
        f23894a.b(preset.getJitterLevel());
        f23895b.b(preset.getVerticalShake());
        f23896c.b(preset.getExpFlickerLevel());
        f23897d.b(preset.getChroma());
        f23898e.b(preset.getTemperature());
        f23899f.b(preset.getTint());
        f23900g.b(preset.getSaturation());
        f23901h.b(preset.getBlur());
        f23902i.b(preset.getGrainStrength());
        f23903j.b(preset.getGrainSize());
        f23904k.b(preset.getGrainSmoothness());
        f23905l.b(preset.getGrainChroma());
        f23907n.b(preset.getVignette());
        f23908o.b(preset.getVerticalScratch());
        f23909p.b(preset.getStainScratchIntensity());
        f23910q.b(preset.getScratchesColor());
        f23911r.b(preset.getPerfColor());
        Float halationIntensityV2 = preset.getHalationIntensityV2();
        f23912s.b(halationIntensityV2 != null ? halationIntensityV2.floatValue() : preset.getHalationIntensity() * 0.6f);
        f23913t.b(preset.getHalationCuttoff());
        f23914u.b(preset.getHalationRadius());
        f23915v.b(preset.getHalationHueGreen());
        f23916w.b(preset.getHalationHueBlue());
        f23917x.b(preset.getLightLeakBlueStatic());
        f23918y.b(preset.getLightLeakRedStatic());
        f23919z.b(preset.getLightLeakHoles());
        A.b(preset.getPseudoExposure());
        B.b(preset.getContrast());
        C.b(preset.getGrainDarkLevel());
        double[] characteristicCurveX = preset.getCharacteristicCurveX();
        u0.q(characteristicCurveX, "<set-?>");
        v3.a0.f31951k = characteristicCurveX;
        double[] characteristicCurveY = preset.getCharacteristicCurveY();
        u0.q(characteristicCurveY, "<set-?>");
        v3.a0.f31950j = characteristicCurveY;
        Iterator it = D.iterator();
        while (it.hasNext()) {
            ((z1) ((c) it.next())).a();
        }
    }

    /* JADX WARN: Unreachable blocks removed: 20, instructions: 20 */
    public static void b() {
        SharedPreferences sharedPreferences = y4.g1.f33744b;
        if (sharedPreferences == null) {
            u0.r0("processorSettings");
            throw null;
        }
        f23894a.b(sharedPreferences.getInt("jitterLevel", 3));
        SharedPreferences sharedPreferences2 = y4.g1.f33744b;
        if (sharedPreferences2 == null) {
            u0.r0("processorSettings");
            throw null;
        }
        f23895b.b(sharedPreferences2.getInt("verticalShake", 2));
        SharedPreferences sharedPreferences3 = y4.g1.f33744b;
        if (sharedPreferences3 == null) {
            u0.r0("processorSettings");
            throw null;
        }
        f23896c.b(sharedPreferences3.getInt("expflickerLevel", 10));
        SharedPreferences sharedPreferences4 = y4.g1.f33744b;
        if (sharedPreferences4 == null) {
            u0.r0("processorSettings");
            throw null;
        }
        f23898e.b(sharedPreferences4.getInt("temperature", 6600));
        SharedPreferences sharedPreferences5 = y4.g1.f33744b;
        if (sharedPreferences5 == null) {
            u0.r0("processorSettings");
            throw null;
        }
        f23899f.b(sharedPreferences5.getInt("tint", 0));
        SharedPreferences sharedPreferences6 = y4.g1.f33744b;
        if (sharedPreferences6 == null) {
            u0.r0("processorSettings");
            throw null;
        }
        f23900g.b(sharedPreferences6.getFloat("saturation", 1.0f));
        SharedPreferences sharedPreferences7 = y4.g1.f33744b;
        if (sharedPreferences7 == null) {
            u0.r0("processorSettings");
            throw null;
        }
        B.b(sharedPreferences7.getFloat("KEY_CONTRAST", 1.0f));
        SharedPreferences sharedPreferences8 = y4.g1.f33744b;
        if (sharedPreferences8 == null) {
            u0.r0("processorSettings");
            throw null;
        }
        f23901h.b(sharedPreferences8.getInt("blur", 2));
        SharedPreferences sharedPreferences9 = y4.g1.f33744b;
        if (sharedPreferences9 == null) {
            u0.r0("processorSettings");
            throw null;
        }
        f23902i.b(sharedPreferences9.getFloat("grainStrength", 0.12f));
        SharedPreferences sharedPreferences10 = y4.g1.f33744b;
        if (sharedPreferences10 == null) {
            u0.r0("processorSettings");
            throw null;
        }
        f23903j.b(sharedPreferences10.getFloat("grainSize", 0.21f));
        SharedPreferences sharedPreferences11 = y4.g1.f33744b;
        if (sharedPreferences11 == null) {
            u0.r0("processorSettings");
            throw null;
        }
        f23904k.b(sharedPreferences11.getFloat("KEY_GRAIN_SMOOTHNESS", 0.27f));
        SharedPreferences sharedPreferences12 = y4.g1.f33744b;
        if (sharedPreferences12 == null) {
            u0.r0("processorSettings");
            throw null;
        }
        f23905l.b(sharedPreferences12.getFloat("KEY_GRAIN_CHROMA", 0.76f));
        SharedPreferences sharedPreferences13 = y4.g1.f33744b;
        if (sharedPreferences13 == null) {
            u0.r0("processorSettings");
            throw null;
        }
        C.b(sharedPreferences13.getFloat("KEY_GRAIN_DARK_LEVEL", 0.0f));
        SharedPreferences sharedPreferences14 = y4.g1.f33744b;
        if (sharedPreferences14 == null) {
            u0.r0("processorSettings");
            throw null;
        }
        f23907n.b(sharedPreferences14.getFloat("vignette", 0.15f));
        SharedPreferences sharedPreferences15 = y4.g1.f33744b;
        if (sharedPreferences15 == null) {
            u0.r0("processorSettings");
            throw null;
        }
        f23897d.b(sharedPreferences15.getFloat("chroma", 0.0f));
        SharedPreferences sharedPreferences16 = y4.g1.f33744b;
        if (sharedPreferences16 == null) {
            u0.r0("processorSettings");
            throw null;
        }
        f23908o.b(sharedPreferences16.getFloat("verticalScratch", 0.9f));
        SharedPreferences sharedPreferences17 = y4.g1.f33744b;
        if (sharedPreferences17 == null) {
            u0.r0("processorSettings");
            throw null;
        }
        f23909p.b(sharedPreferences17.getInt("stainScratchIntensity", 95));
        SharedPreferences sharedPreferences18 = y4.g1.f33744b;
        if (sharedPreferences18 == null) {
            u0.r0("processorSettings");
            throw null;
        }
        f23910q.b(sharedPreferences18.getFloat("scratchesColor", 0.5f));
        SharedPreferences sharedPreferences19 = y4.g1.f33744b;
        if (sharedPreferences19 == null) {
            u0.r0("processorSettings");
            throw null;
        }
        f23911r.b(sharedPreferences19.getFloat("perfColor", 0.0f));
        SharedPreferences sharedPreferences20 = y4.g1.f33744b;
        if (sharedPreferences20 == null) {
            u0.r0("processorSettings");
            throw null;
        }
        f23912s.b(sharedPreferences20.getFloat("halationIntensity", 0.0f));
        SharedPreferences sharedPreferences21 = y4.g1.f33744b;
        if (sharedPreferences21 == null) {
            u0.r0("processorSettings");
            throw null;
        }
        f23913t.b(sharedPreferences21.getFloat("halationCuttoff", 0.35f));
        SharedPreferences sharedPreferences22 = y4.g1.f33744b;
        if (sharedPreferences22 == null) {
            u0.r0("processorSettings");
            throw null;
        }
        f23914u.b(sharedPreferences22.getInt("halationRadius", 0));
        SharedPreferences sharedPreferences23 = y4.g1.f33744b;
        if (sharedPreferences23 == null) {
            u0.r0("processorSettings");
            throw null;
        }
        f23915v.b(sharedPreferences23.getFloat("halationHueGreen", 0.3f));
        SharedPreferences sharedPreferences24 = y4.g1.f33744b;
        if (sharedPreferences24 == null) {
            u0.r0("processorSettings");
            throw null;
        }
        f23916w.b(sharedPreferences24.getFloat("halationHueBlue", 0.04f));
        SharedPreferences sharedPreferences25 = y4.g1.f33744b;
        if (sharedPreferences25 == null) {
            u0.r0("processorSettings");
            throw null;
        }
        f23917x.b(sharedPreferences25.getFloat("KEY_LIGHT_LEAK_BLUE_STATIC", 0.0f));
        SharedPreferences sharedPreferences26 = y4.g1.f33744b;
        if (sharedPreferences26 == null) {
            u0.r0("processorSettings");
            throw null;
        }
        f23918y.b(sharedPreferences26.getFloat("KEY_LIGHT_LEAK_RED_STATIC", 0.0f));
        SharedPreferences sharedPreferences27 = y4.g1.f33744b;
        if (sharedPreferences27 == null) {
            u0.r0("processorSettings");
            throw null;
        }
        f23919z.b(sharedPreferences27.getFloat("KEY_LIGHT_LEAK_HOLES", 0.0f));
        SharedPreferences sharedPreferences28 = y4.g1.f33744b;
        if (sharedPreferences28 == null) {
            u0.r0("processorSettings");
            throw null;
        }
        A.b(sharedPreferences28.getFloat("KEY_PSEUDO_EXPOSURE", 1.0f));
        SharedPreferences sharedPreferences29 = y4.g1.f33744b;
        if (sharedPreferences29 == null) {
            u0.r0("processorSettings");
            throw null;
        }
        String str = "";
        String string = sharedPreferences29.getString("CharacteristicCurveX", str);
        if (string == null) {
            string = str;
        }
        if (u0.h(string, "")) {
            v3.a0.f31951k = new double[]{0.0d, 50.0d, 100.0d, 150.0d, 200.0d, 255.0d};
        } else {
            Object objB = new Gson().b(string);
            u0.p(objB, "Gson().fromJson(Characte\u2026 DoubleArray::class.java)");
            v3.a0.f31951k = (double[]) objB;
        }
        SharedPreferences sharedPreferences30 = y4.g1.f33744b;
        if (sharedPreferences30 == null) {
            u0.r0("processorSettings");
            throw null;
        }
        String string2 = sharedPreferences30.getString("CharacteristicCurveY", str);
        if (string2 != null) {
            str = string2;
        }
        if (u0.h(str, "")) {
            v3.a0.f31950j = new double[]{20.0d, 50.0d, 100.0d, 150.0d, 200.0d, 255.0d};
        } else {
            Object objB2 = new Gson().b(str);
            u0.p(objB2, "Gson().fromJson(Characte\u2026 DoubleArray::class.java)");
            v3.a0.f31950j = (double[]) objB2;
        }
        Iterator it = D.iterator();
        while (it.hasNext()) {
            ((z1) ((c) it.next())).a();
        }
    }

    /* JADX WARN: Code duplicated, block: B:15:0x0119  */
    /* JADX WARN: Code duplicated, block: B:16:0x011d  */
    /* JADX WARN: Code duplicated, block: B:21:0x012b  */
    /* JADX WARN: Code duplicated, block: B:23:0x012f  */
    /* JADX WARN: Code duplicated, block: B:24:0x0133  */
    /* JADX WARN: Code duplicated, block: B:29:0x0141  */
    /* JADX WARN: Code duplicated, block: B:31:0x0145  */
    /* JADX WARN: Code duplicated, block: B:32:0x0149  */
    /* JADX WARN: Code duplicated, block: B:37:0x0157  */
    /* JADX WARN: Code duplicated, block: B:39:0x015b  */
    /* JADX WARN: Code duplicated, block: B:40:0x015e  */
    /* JADX WARN: Code duplicated, block: B:45:0x016a  */
    public static Preset c(String str, p4.c cVar, FrameMode frameMode) {
        int i6;
        int i10;
        boolean z10;
        p4.b bVar;
        String id;
        p4.b bVar2;
        String name;
        p4.b bVar3;
        String code;
        p4.b bVar4;
        String previewBase64;
        CustomFilterEntity customFilterEntity;
        CustomFilterEntity customFilterEntity2;
        CustomFilterEntity customFilterEntity3;
        CustomFilterEntity customFilterEntity4;
        u0.q(frameMode, "frameMode");
        StringBuilder sb2 = new StringBuilder();
        sb2.append(UUID.randomUUID());
        sb2.append(System.currentTimeMillis());
        sb2.append(System.nanoTime());
        String string = sb2.toString();
        String strE = "new preset";
        int iA = f23894a.a();
        int iA2 = f23895b.a();
        int iA3 = f23896c.a();
        float fA = f23897d.a();
        int iA4 = f23898e.a();
        int iA5 = f23899f.a();
        float fA2 = f23900g.a();
        float fA3 = B.a();
        int iA6 = f23901h.a();
        float fA4 = f23902i.a();
        float fA5 = f23903j.a();
        float fA6 = f23904k.a();
        float fA7 = f23905l.a();
        float fA8 = C.a();
        float fA9 = f23907n.a();
        float fA10 = f23908o.a();
        int iA7 = f23909p.a();
        float fA11 = f23910q.a();
        float fA12 = f23911r.a();
        f1 f1Var = f23912s;
        float fS = za.z.s(f1Var.a() / 0.6f, 0.0f, 1.0f);
        Float fValueOf = Float.valueOf(f1Var.a());
        float fA13 = f23913t.a();
        int iA8 = f23914u.a();
        float fA14 = f23915v.a();
        float fA15 = f23916w.a();
        float fA16 = f23917x.a();
        float fA17 = f23918y.a();
        float fA18 = f23919z.a();
        float fA19 = A.a();
        if (!(cVar instanceof p4.p)) {
            if (cVar instanceof p4.o ? true : cVar instanceof p4.a) {
                i10 = 1;
            } else {
                i6 = 2;
            }
            z10 = cVar instanceof p4.b;
            if (z10) {
                bVar = (p4.b) cVar;
            } else {
                bVar = null;
            }
            if (bVar != null || (customFilterEntity4 = bVar.f28969c) == null) {
                id = null;
            } else {
                id = customFilterEntity4.getId();
            }
            if (z10) {
                bVar2 = (p4.b) cVar;
            } else {
                bVar2 = null;
            }
            if (bVar2 != null || (customFilterEntity3 = bVar2.f28969c) == null) {
                name = null;
            } else {
                name = customFilterEntity3.getName();
            }
            if (z10) {
                bVar3 = (p4.b) cVar;
            } else {
                bVar3 = null;
            }
            if (bVar3 != null || (customFilterEntity2 = bVar3.f28969c) == null) {
                code = null;
            } else {
                code = customFilterEntity2.getCode();
            }
            if (z10) {
                bVar4 = (p4.b) cVar;
            } else {
                bVar4 = null;
            }
            if (bVar4 != null || (customFilterEntity = bVar4.f28969c) == null) {
                previewBase64 = null;
            } else {
                previewBase64 = customFilterEntity.getPreviewBase64();
            }
            return new Preset(string, strE, str, iA, iA2, iA3, fA, iA4, iA5, fA2, fA3, iA6, fA4, fA5, fA6, fA7, fA8, fA9, fA10, iA7, fA11, fA12, fS, fValueOf, fA13, iA8, fA14, fA15, fA16, fA17, fA18, fA19, i10, id, name, code, previewBase64, v3.a0.f31951k, v3.a0.f31950j, frameMode, true);
        }
        i6 = ((p4.p) cVar).f29004d;
        i10 = i6;
        z10 = cVar instanceof p4.b;
        if (z10) {
            bVar = (p4.b) cVar;
        } else {
            bVar = null;
        }
        if (bVar != null) {
            id = null;
        } else {
            id = null;
        }
        if (z10) {
            bVar2 = (p4.b) cVar;
        } else {
            bVar2 = null;
        }
        if (bVar2 != null) {
            name = null;
        } else {
            name = null;
        }
        if (z10) {
            bVar3 = (p4.b) cVar;
        } else {
            bVar3 = null;
        }
        if (bVar3 != null) {
            code = null;
        } else {
            code = null;
        }
        if (z10) {
            bVar4 = (p4.b) cVar;
        } else {
            bVar4 = null;
        }
        if (bVar4 != null) {
            previewBase64 = null;
        } else {
            previewBase64 = null;
        }
        return new Preset(string, strE, str, iA, iA2, iA3, fA, iA4, iA5, fA2, fA3, iA6, fA4, fA5, fA6, fA7, fA8, fA9, fA10, iA7, fA11, fA12, fS, fValueOf, fA13, iA8, fA14, fA15, fA16, fA17, fA18, fA19, i10, id, name, code, previewBase64, v3.a0.f31951k, v3.a0.f31950j, frameMode, true);
    }

    public static void d() {
        f23912s.b(0.0f);
        f23914u.b(0);
        f23919z.b(0.0f);
        f23918y.b(0.0f);
        f23917x.b(0.0f);
        Iterator it = D.iterator();
        while (it.hasNext()) {
            ((z1) ((c) it.next())).a();
        }
    }
}
