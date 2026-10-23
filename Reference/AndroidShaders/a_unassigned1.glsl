uniform samplerExternalOES frameTexture;
uniform sampler2D mTextureID1;
uniform sampler2D mTextureID2;
vec4 frame(){
   vec4 colorIn;
   
   highp float xcoord;
    xcoord = (vTextureCoord.x )*1.06 - 0.048;

    float scale = 0.5;
   if(vTextureCoord.x  > 0.13 && ( vTextureCoord.y  > 0.107 && vTextureCoord.y <0.88)){
      colorIn = textureLod(mTextureID1, vec2(xcoord / 1.06,  (vTextureCoord.y ))*1.06 - 0.03 , 0.0);
   } else if(vTextureCoord.x  > 0.13 &&  vTextureCoord.y  < 0.107 ){
      colorIn = textureLod(mTextureID2, vec2(xcoord,  (vTextureCoord.y )*1.06 +0.817)- 0.03 , 0.0 );
   } else if(vTextureCoord.x  > 0.13 &&  vTextureCoord.y  > 0.88 ){
      colorIn = textureLod(mTextureID, vec2(xcoord,  (vTextureCoord.y )*1.06 -0.817)- 0.03 , 0.0 );
   } else if(vTextureCoord.x  > 0.072 && vTextureCoord.x  < 0.13 && vTextureCoord.y  < 0.41 ){
      colorIn = textureLod(mTextureID1, vec2(xcoord*scale,  ((vTextureCoord.y )*1.06 +0.307)- 0.03 )*scale , 0.0);
   } else if(vTextureCoord.x  > 0.072 && vTextureCoord.x  < 0.13 && vTextureCoord.y  > 0.484 ){
      colorIn = textureLod(mTextureID, vec2(xcoord*scale,  ((vTextureCoord.y )*1.06 -0.517)- 0.03)*scale ,0.0 );
   }

   vec4 hawaiiFrameTextureColor;
   hawaiiFrameTextureColor = texture(frameTexture, vTextureCoord);
   if(vTextureCoord.x  > 0.072 && hawaiiFrameTextureColor.g >hawaiiFrameTextureColor.r*1.0){
      hawaiiFrameTextureColor.a = 1.0 - hawaiiFrameTextureColor.g;
      hawaiiFrameTextureColor.g = 0.0;
      hawaiiFrameTextureColor.r = 0.0;
      hawaiiFrameTextureColor.b = 0.0;
   }
   mediump vec4 processedColor;
   if(vTextureCoord.x < 1.0){
        processedColor.rgb = hawaiiFrameTextureColor.rgb + colorIn.rgb * colorIn.a * (1.0 - hawaiiFrameTextureColor.a);
        //processedColor.g = hawaiiFrameTextureColor.g + colorIn.g * colorIn.a * (1.0 - hawaiiFrameTextureColor.a);
        //processedColor.b = hawaiiFrameTextureColor.b + colorIn.b * colorIn.a * (1.0 - hawaiiFrameTextureColor.a);
        processedColor.a = hawaiiFrameTextureColor.a + colorIn.a * (1.0 - hawaiiFrameTextureColor.a);
   } else {
        processedColor = vec4(0.0,0.0,0.0,1.0);
   }   
   return processedColor;
}