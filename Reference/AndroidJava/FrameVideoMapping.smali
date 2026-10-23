.class public final synthetic Lv3/h0;
.super Ljava/lang/Object;

# interfaces
.implements Ljava/lang/Runnable;


# instance fields
.field public final synthetic a:Landroid/graphics/SurfaceTexture;

.field public final synthetic b:Landroid/net/Uri;

.field public final synthetic c:Lv3/o0;

.field public final synthetic d:Z

.field public final synthetic e:Ljava/lang/Integer;

.field public final synthetic f:Li8/a;

.field public final synthetic i:Lcom/dwsh/super16/FrameMode;


# direct methods
.method public synthetic constructor <init>(Landroid/graphics/SurfaceTexture;Landroid/net/Uri;ZLjava/lang/Integer;Lj4/d0;Lcom/dwsh/super16/FrameMode;)V
    .locals 5

    sget-object v0, Lv3/o0;->a:Lv3/o0;

    const-string v4, ""

    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    const/4 v4, 0x5

    iput-object p1, p0, Lv3/h0;->a:Landroid/graphics/SurfaceTexture;

    const/4 v2, 0x2

    iput-object p2, p0, Lv3/h0;->b:Landroid/net/Uri;

    const/4 v2, 0x5

    iput-object v0, p0, Lv3/h0;->c:Lv3/o0;

    const/4 v3, 0x7

    iput-boolean p3, p0, Lv3/h0;->d:Z

    iput-object p4, p0, Lv3/h0;->e:Ljava/lang/Integer;

    iput-object p5, p0, Lv3/h0;->f:Li8/a;

    iput-object p6, p0, Lv3/h0;->i:Lcom/dwsh/super16/FrameMode;

    const/4 v3, 0x7

    return-void
.end method


# virtual methods
.method public final run()V
    .locals 15

    iget-object v0, p0, Lv3/h0;->a:Landroid/graphics/SurfaceTexture;

    const/4 v14, 0x2

    iget-object v1, p0, Lv3/h0;->b:Landroid/net/Uri;

    const/4 v14, 0x7

    iget-object v2, p0, Lv3/h0;->c:Lv3/o0;

    const/4 v14, 0x6

    iget-boolean v3, p0, Lv3/h0;->d:Z

    const/4 v14, 0x4

    iget-object v4, p0, Lv3/h0;->e:Ljava/lang/Integer;

    const/4 v14, 0x1

    iget-object v5, p0, Lv3/h0;->f:Li8/a;

    const/4 v14, 0x3

    iget-object v6, p0, Lv3/h0;->i:Lcom/dwsh/super16/FrameMode;

    const-wide v7, -0x2dd0604f6f068L

    const/4 v14, 0x4

    invoke-static {v7, v8}, Ll/e;->e(J)Ljava/lang/String;

    move-result-object v14

    move-object v7, v14

    invoke-static {v0, v7}, Ly4/u0;->q(Ljava/lang/Object;Ljava/lang/String;)V

    const/4 v14, 0x2

    const-wide v7, -0x2dd1104f6f068L

    invoke-static {v7, v8}, Ll/e;->e(J)Ljava/lang/String;

    move-result-object v7

    invoke-static {v2, v7}, Ly4/u0;->q(Ljava/lang/Object;Ljava/lang/String;)V

    const/4 v14, 0x4

    const-wide v7, -0x2dd2a04f6f068L

    const/4 v14, 0x3

    invoke-static {v7, v8}, Ll/e;->e(J)Ljava/lang/String;

    move-result-object v7

    invoke-static {v5, v7}, Ly4/u0;->q(Ljava/lang/Object;Ljava/lang/String;)V

    const/4 v14, 0x5

    const-wide v7, -0x2dd3f04f6f068L

    const/4 v14, 0x1

    invoke-static {v7, v8}, Ll/e;->e(J)Ljava/lang/String;

    move-result-object v7

    invoke-static {v6, v7}, Ly4/u0;->q(Ljava/lang/Object;Ljava/lang/String;)V

    const/4 v14, 0x0

    move v7, v14

    const/4 v14, 0x0

    move v8, v14

    :try_start_0
    const/4 v14, 0x6

    sget-object v9, Lv3/o0;->a:Lv3/o0;

    const/4 v14, 0x3

    sget-object v10, Lv3/i;->i:Lv3/i;

    const/4 v14, 0x3

    invoke-static {v9, v10}, Lc6/a;->b0(Ljava/lang/Object;Li8/a;)V

    const/4 v14, 0x5

    sput-boolean v8, Lv3/o0;->c:Z

    const/4 v14, 0x5

    sget-object v9, Lv3/o0;->b:Landroid/media/MediaPlayer;

    if-eqz v9, :cond_0

    const/4 v14, 0x3

    invoke-virtual {v9}, Landroid/media/MediaPlayer;->reset()V

    const/4 v14, 0x5

    :cond_0
    const/4 v14, 0x4

    sget-object v9, Lv3/o0;->d:Landroid/view/Surface;

    if-eqz v9, :cond_1

    const/4 v14, 0x1

    invoke-virtual {v9}, Landroid/view/Surface;->release()V

    const/4 v14, 0x6

    :cond_1
    const/4 v14, 0x4

    sput-object v7, Lv3/o0;->d:Landroid/view/Surface;
    :try_end_0
    .catch Ljava/lang/Exception; {:try_start_0 .. :try_end_0} :catch_0

    goto :goto_0

    :catch_0
    move-exception v9

    invoke-static {v9, v9}, La6/o;->u(Ljava/lang/Exception;Ljava/lang/Exception;)V

    const/4 v14, 0x5

    :goto_0
    new-instance v9, Landroid/view/Surface;

    const/4 v14, 0x7

    invoke-direct {v9, v0}, Landroid/view/Surface;-><init>(Landroid/graphics/SurfaceTexture;)V

    const/4 v14, 0x7

    sput-object v9, Lv3/o0;->d:Landroid/view/Surface;

    const/16 v9, 0x1e

    const/4 v14, 0x6

    if-nez v1, :cond_2

    const/4 v14, 0x3

    goto :goto_2

    :cond_2
    const/4 v14, 0x5

    new-instance v10, Landroid/media/MediaExtractor;

    invoke-direct {v10}, Landroid/media/MediaExtractor;-><init>()V

    :try_start_1
    sget-object v11, Lcom/dwsh/super16/Super16App;->b:Lcom/dwsh/super16/Super16App;

    invoke-static {}, Landroidx/activity/result/j;->m()Lcom/dwsh/super16/Super16App;

    move-result-object v14

    move-object v11, v14

    invoke-virtual {v10, v11, v1, v7}, Landroid/media/MediaExtractor;->setDataSource(Landroid/content/Context;Landroid/net/Uri;Ljava/util/Map;)V

    const/4 v14, 0x5

    invoke-virtual {v10}, Landroid/media/MediaExtractor;->getTrackCount()I

    move-result v14

    move v1, v14

    move v7, v8

    :goto_1
    if-ge v7, v1, :cond_4

    invoke-virtual {v10, v7}, Landroid/media/MediaExtractor;->getTrackFormat(I)Landroid/media/MediaFormat;

    move-result-object v11

    const-wide v12, -0x2dd4304f6f068L

    const/4 v14, 0x2

    invoke-static {v12, v13}, Ll/e;->e(J)Ljava/lang/String;

    move-result-object v14

    move-object v12, v14

    invoke-static {v11, v12}, Ly4/u0;->p(Ljava/lang/Object;Ljava/lang/String;)V

    const/4 v14, 0x7

    const-wide v12, -0x2dd6704f6f068L

    invoke-static {v12, v13}, Ll/e;->e(J)Ljava/lang/String;

    move-result-object v14

    move-object v12, v14

    invoke-virtual {v11, v12}, Landroid/media/MediaFormat;->containsKey(Ljava/lang/String;)Z

    move-result v14

    move v12, v14

    if-eqz v12, :cond_3

    const-wide v12, -0x2dd7c04f6f068L

    const/4 v14, 0x7

    invoke-static {v12, v13}, Ll/e;->e(J)Ljava/lang/String;

    move-result-object v14

    move-object v12, v14

    invoke-virtual {v11, v12}, Landroid/media/MediaFormat;->getInteger(Ljava/lang/String;)I

    move-result v14

    move v9, v14
    :try_end_1
    .catch Ljava/io/IOException; {:try_start_1 .. :try_end_1} :catch_1
    .catchall {:try_start_1 .. :try_end_1} :catchall_0

    :cond_3
    const/4 v14, 0x1

    add-int/lit8 v7, v7, 0x1

    goto :goto_1

    :catchall_0
    move-exception v0

    goto/16 :goto_9

    :catch_1
    move-exception v1

    :try_start_2
    const/4 v14, 0x5

    invoke-virtual {v1}, Ljava/lang/Throwable;->printStackTrace()V
    :try_end_2
    .catchall {:try_start_2 .. :try_end_2} :catchall_0

    :cond_4
    const/4 v14, 0x1

    invoke-virtual {v10}, Landroid/media/MediaExtractor;->release()V

    const/4 v14, 0x4

    :goto_2
    invoke-static {v9}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;

    move-result-object v1

    sput-object v1, Lv3/o0;->e:Ljava/lang/Integer;

    const/4 v14, 0x1

    sput-boolean v3, Lv3/o0;->f:Z

    const/4 v14, 0x3

    :try_start_3
    const/4 v14, 0x7

    sget-object v1, Lv3/o0;->b:Landroid/media/MediaPlayer;

    const/4 v14, 0x4

    if-nez v1, :cond_5

    const/4 v14, 0x1

    new-instance v1, Landroid/media/MediaPlayer;

    invoke-direct {v1}, Landroid/media/MediaPlayer;-><init>()V

    const/4 v14, 0x3

    invoke-virtual {v1, v2}, Landroid/media/MediaPlayer;->setOnErrorListener(Landroid/media/MediaPlayer$OnErrorListener;)V

    sput-object v1, Lv3/o0;->b:Landroid/media/MediaPlayer;

    const/4 v14, 0x5

    :cond_5
    const/4 v14, 0x4

    sget-object v1, Lv3/o0;->b:Landroid/media/MediaPlayer;

    if-eqz v1, :cond_c

    const/4 v14, 0x3

    sget-object v2, Lv3/k0;->a:[I

    invoke-virtual {v6}, Ljava/lang/Enum;->ordinal()I

    move-result v14

    move v3, v14

    aget v2, v2, v3

    packed-switch v2, :pswitch_data_0

    const/4 v14, 0x3

    goto/16 :goto_7

    :pswitch_0
    const/4 v14, 0x2

    sget-object v2, Lv3/m1;->a:Lv3/m1;

    sget-object v3, Lcom/dwsh/super16/Super16App;->b:Lcom/dwsh/super16/Super16App;

    invoke-static {}, Landroidx/activity/result/j;->m()Lcom/dwsh/super16/Super16App;

    move-result-object v14

    move-object v3, v14

    const-wide v6, -0x2dc2304f6f068L

    invoke-static {v6, v7}, Ll/e;->e(J)Ljava/lang/String;

    move-result-object v6

    invoke-virtual {v2, v3, v6}, Lv3/m1;->d(Landroid/content/Context;Ljava/lang/String;)Lv3/l1;

    move-result-object v2

    invoke-virtual {v1, v2}, Landroid/media/MediaPlayer;->setDataSource(Landroid/media/MediaDataSource;)V

    goto/16 :goto_3

    :pswitch_1
    const/4 v14, 0x4

    sget-object v2, Lv3/m1;->a:Lv3/m1;

    const/4 v14, 0x3

    sget-object v3, Lcom/dwsh/super16/Super16App;->b:Lcom/dwsh/super16/Super16App;

    invoke-static {}, Landroidx/activity/result/j;->m()Lcom/dwsh/super16/Super16App;

    move-result-object v14

    move-object v3, v14

    const-wide v6, -0x2dc0c04f6f068L

    const/4 v14, 0x6

    invoke-static {v6, v7}, Ll/e;->e(J)Ljava/lang/String;

    move-result-object v14

    move-object v6, v14

    invoke-virtual {v2, v3, v6}, Lv3/m1;->d(Landroid/content/Context;Ljava/lang/String;)Lv3/l1;

    move-result-object v2

    invoke-virtual {v1, v2}, Landroid/media/MediaPlayer;->setDataSource(Landroid/media/MediaDataSource;)V

    goto/16 :goto_3

    :pswitch_2
    const/4 v14, 0x4

    sget-object v2, Lv3/m1;->a:Lv3/m1;

    const/4 v14, 0x7

    sget-object v3, Lcom/dwsh/super16/Super16App;->b:Lcom/dwsh/super16/Super16App;

    invoke-static {}, Landroidx/activity/result/j;->m()Lcom/dwsh/super16/Super16App;

    move-result-object v3

    const-wide v6, -0x2dc5504f6f068L

    const/4 v14, 0x5

    invoke-static {v6, v7}, Ll/e;->e(J)Ljava/lang/String;

    move-result-object v14

    move-object v6, v14

    invoke-virtual {v2, v3, v6}, Lv3/m1;->d(Landroid/content/Context;Ljava/lang/String;)Lv3/l1;

    move-result-object v14

    move-object v2, v14

    invoke-virtual {v1, v2}, Landroid/media/MediaPlayer;->setDataSource(Landroid/media/MediaDataSource;)V

    const/4 v14, 0x6

    goto :goto_3

    :pswitch_3
    sget-object v2, Lv3/m1;->a:Lv3/m1;

    const/4 v14, 0x1

    sget-object v3, Lcom/dwsh/super16/Super16App;->b:Lcom/dwsh/super16/Super16App;

    invoke-static {}, Landroidx/activity/result/j;->m()Lcom/dwsh/super16/Super16App;

    move-result-object v3

    const-wide v6, -0x2ddbe04f6f068L

    const/4 v14, 0x2

    invoke-static {v6, v7}, Ll/e;->e(J)Ljava/lang/String;

    move-result-object v6

    invoke-virtual {v2, v3, v6}, Lv3/m1;->d(Landroid/content/Context;Ljava/lang/String;)Lv3/l1;

    move-result-object v2

    invoke-virtual {v1, v2}, Landroid/media/MediaPlayer;->setDataSource(Landroid/media/MediaDataSource;)V

    const/4 v14, 0x2

    goto :goto_3

    :pswitch_4
    sget-object v2, Lv3/m1;->a:Lv3/m1;

    sget-object v3, Lcom/dwsh/super16/Super16App;->b:Lcom/dwsh/super16/Super16App;

    invoke-static {}, Landroidx/activity/result/j;->m()Lcom/dwsh/super16/Super16App;

    move-result-object v14

    move-object v3, v14

    const-wide v6, -0x2dd8704f6f068L

    const/4 v14, 0x4

    invoke-static {v6, v7}, Ll/e;->e(J)Ljava/lang/String;

    move-result-object v6

    invoke-virtual {v2, v3, v6}, Lv3/m1;->d(Landroid/content/Context;Ljava/lang/String;)Lv3/l1;

    move-result-object v14

    move-object v2, v14

    invoke-virtual {v1, v2}, Landroid/media/MediaPlayer;->setDataSource(Landroid/media/MediaDataSource;)V

    const/4 v14, 0x2

    goto :goto_3

    :pswitch_5
    const/4 v14, 0x1

    sget-object v2, Lv3/m1;->a:Lv3/m1;

    sget-object v3, Lcom/dwsh/super16/Super16App;->b:Lcom/dwsh/super16/Super16App;

    const/4 v14, 0x5

    invoke-static {}, Landroidx/activity/result/j;->m()Lcom/dwsh/super16/Super16App;

    move-result-object v14

    move-object v3, v14

    const-wide v6, -0x2ddd004f6f068L

    invoke-static {v6, v7}, Ll/e;->e(J)Ljava/lang/String;

    move-result-object v14

    move-object v6, v14

    invoke-virtual {v2, v3, v6}, Lv3/m1;->d(Landroid/content/Context;Ljava/lang/String;)Lv3/l1;

    move-result-object v14

    move-object v2, v14

    invoke-virtual {v1, v2}, Landroid/media/MediaPlayer;->setDataSource(Landroid/media/MediaDataSource;)V

    goto :goto_3

    :pswitch_6
    sget-object v2, Lv3/m1;->a:Lv3/m1;

    const/4 v14, 0x3

    sget-object v3, Lcom/dwsh/super16/Super16App;->b:Lcom/dwsh/super16/Super16App;

    const/4 v14, 0x6

    invoke-static {}, Landroidx/activity/result/j;->m()Lcom/dwsh/super16/Super16App;

    move-result-object v14

    move-object v3, v14

    const-wide v6, -0x2dd3904f6f068L

    invoke-static {v6, v7}, Ll/e;->e(J)Ljava/lang/String;

    move-result-object v14

    move-object v6, v14

    invoke-virtual {v2, v3, v6}, Lv3/m1;->d(Landroid/content/Context;Ljava/lang/String;)Lv3/l1;

    move-result-object v14

    move-object v2, v14

    invoke-virtual {v1, v2}, Landroid/media/MediaPlayer;->setDataSource(Landroid/media/MediaDataSource;)V

    const/4 v14, 0x1

    :goto_3
    sget-object v2, Lv3/o0;->d:Landroid/view/Surface;

    const/4 v14, 0x2

    const/4 v14, 0x1

    move v3, v14

    if-eqz v2, :cond_6

    invoke-virtual {v2}, Landroid/view/Surface;->isValid()Z

    move-result v14

    move v2, v14

    if-ne v2, v3, :cond_6

    const/4 v14, 0x4

    move v8, v3

    :cond_6
    const/4 v14, 0x7

    if-eqz v8, :cond_c

    const/4 v14, 0x5

    invoke-static {v0}, Lgb/m;->B(Landroid/graphics/SurfaceTexture;)Z

    move-result v2

    if-eqz v2, :cond_7

    const/4 v14, 0x7

    goto/16 :goto_7

    :cond_7
    const/4 v14, 0x4

    sget-object v2, Lv3/o0;->d:Landroid/view/Surface;

    invoke-virtual {v1, v2}, Landroid/media/MediaPlayer;->setSurface(Landroid/view/Surface;)V

    invoke-virtual {v1, v3}, Landroid/media/MediaPlayer;->setLooping(Z)V

    const/4 v14, 0x3

    new-instance v2, Landroidx/lifecycle/y0;

    const/4 v14, 0x4

    move v6, v14

    invoke-direct {v2, v0, v6}, Landroidx/lifecycle/y0;-><init>(Ljava/lang/Object;I)V

    const/4 v14, 0x1

    invoke-static {v1, v2}, Lc6/a;->b0(Ljava/lang/Object;Li8/a;)V

    invoke-virtual {v1}, Landroid/media/MediaPlayer;->prepare()V

    if-eqz v4, :cond_9

    invoke-virtual {v4}, Ljava/lang/Number;->intValue()I

    move-result v14

    move v0, v14

    sget v2, Landroid/os/Build$VERSION;->SDK_INT:I

    const/4 v14, 0x1

    const/16 v14, 0x1a

    move v6, v14

    if-lt v2, v6, :cond_8

    sget-object v2, Lv3/o0;->b:Landroid/media/MediaPlayer;

    const/4 v14, 0x1

    if-eqz v2, :cond_9

    const/4 v14, 0x5

    int-to-long v6, v0

    const/4 v14, 0x2

    invoke-static {v2, v6, v7}, Lp0/r;->m(Landroid/media/MediaPlayer;J)V

    goto :goto_4

    :cond_8
    sget-object v2, Lv3/o0;->b:Landroid/media/MediaPlayer;

    const/4 v14, 0x1

    if-eqz v2, :cond_9

    const/4 v14, 0x6

    invoke-virtual {v2, v0}, Landroid/media/MediaPlayer;->seekTo(I)V

    const/4 v14, 0x6

    :cond_9
    :goto_4
    sget-object v0, Lv3/o0;->b:Landroid/media/MediaPlayer;

    const/4 v14, 0x7

    if-nez v0, :cond_a

    goto :goto_6

    :cond_a
    const/4 v14, 0x1

    new-instance v2, Landroid/media/PlaybackParams;

    invoke-direct {v2}, Landroid/media/PlaybackParams;-><init>()V

    const/4 v14, 0x2

    if-eqz v4, :cond_b

    const/4 v14, 0x2

    invoke-virtual {v4}, Ljava/lang/Number;->intValue()I

    const v4, 0x3c23d70a    # 0.01f

    goto :goto_5

    :cond_b
    const/4 v14, 0x3

    const/high16 v14, 0x3f800000    # 1.0f

    move v4, v14

    :goto_5
    invoke-virtual {v2, v4}, Landroid/media/PlaybackParams;->setSpeed(F)Landroid/media/PlaybackParams;

    move-result-object v2

    invoke-virtual {v0, v2}, Landroid/media/MediaPlayer;->setPlaybackParams(Landroid/media/PlaybackParams;)V

    :goto_6
    sget-object v0, Lv3/i;->f:Lv3/i;

    const/4 v14, 0x7

    invoke-static {v1, v0}, Lc6/a;->b0(Ljava/lang/Object;Li8/a;)V

    sput-boolean v3, Lv3/o0;->c:Z
    :try_end_3
    .catch Ljava/io/IOException; {:try_start_3 .. :try_end_3} :catch_3
    .catch Ljava/lang/IllegalStateException; {:try_start_3 .. :try_end_3} :catch_2
    .catchall {:try_start_3 .. :try_end_3} :catchall_1

    goto :goto_7

    :catchall_1
    move-exception v0

    goto :goto_8

    :catch_2
    move-exception v0

    :try_start_4
    invoke-virtual {v0}, Ljava/lang/Throwable;->printStackTrace()V

    const/4 v14, 0x3

    invoke-static {}, Lcom/google/firebase/crashlytics/FirebaseCrashlytics;->getInstance()Lcom/google/firebase/crashlytics/FirebaseCrashlytics;

    move-result-object v1

    invoke-virtual {v1, v0}, Lcom/google/firebase/crashlytics/FirebaseCrashlytics;->recordException(Ljava/lang/Throwable;)V

    const/4 v14, 0x4

    sget-object v0, Lv3/o0;->b:Landroid/media/MediaPlayer;

    if-eqz v0, :cond_c

    const/4 v14, 0x1

    invoke-virtual {v0}, Landroid/media/MediaPlayer;->reset()V

    const/4 v14, 0x2

    goto :goto_7

    :catch_3
    move-exception v0

    invoke-virtual {v0}, Ljava/lang/Throwable;->printStackTrace()V

    const/4 v14, 0x1

    invoke-static {}, Lcom/google/firebase/crashlytics/FirebaseCrashlytics;->getInstance()Lcom/google/firebase/crashlytics/FirebaseCrashlytics;

    move-result-object v1

    invoke-virtual {v1, v0}, Lcom/google/firebase/crashlytics/FirebaseCrashlytics;->recordException(Ljava/lang/Throwable;)V

    sget-object v0, Lv3/o0;->b:Landroid/media/MediaPlayer;

    const/4 v14, 0x4

    if-eqz v0, :cond_c

    const/4 v14, 0x7

    invoke-virtual {v0}, Landroid/media/MediaPlayer;->reset()V
    :try_end_4
    .catchall {:try_start_4 .. :try_end_4} :catchall_1

    :cond_c
    :goto_7
    invoke-interface {v5}, Li8/a;->d()Ljava/lang/Object;

    return-void

    :goto_8
    invoke-interface {v5}, Li8/a;->d()Ljava/lang/Object;

    throw v0

    const/4 v14, 0x1

    :goto_9
    invoke-virtual {v10}, Landroid/media/MediaExtractor;->release()V

    throw v0

    const/4 v14, 0x1

    nop

    :pswitch_data_0
    .packed-switch 0x1
        :pswitch_6
        :pswitch_5
        :pswitch_4
        :pswitch_3
        :pswitch_2
        :pswitch_1
        :pswitch_0
    .end packed-switch
.end method
