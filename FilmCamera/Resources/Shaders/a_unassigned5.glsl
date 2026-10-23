uniform samplerExternalOES frameTexture;
uniform sampler2D mTextureID1;
uniform sampler2D mTextureID2;
vec4 frame(){
   vec4 colorIn;
   
   highp float xcoord;
   xcoord = (vTextureCoord.x )*1.03 - 0.07;

   float slope =- 0.02*vTextureCoord.x;
   float top = 0.085;
   float bottom = 0.953;
   float parallaxTop = 0.894;
   float parallaxBottom = 0.896;
   if( ( vTextureCoord.y  > top  + slope && vTextureCoord.y  < bottom + slope )){
      colorIn = textureLod(mTextureID1, vec2(xcoord / 1.03,  (vTextureCoord.y ))*1.03 - 0.02, 0.0 );
   } else if( vTextureCoord.y  < top + slope){
      colorIn = textureLod(mTextureID2, vec2(xcoord,  ((vTextureCoord.y ))*1.03 + parallaxTop)- 0.02, 0.0  );
   } else if( vTextureCoord.y  > bottom + slope ){
      colorIn = textureLod(mTextureID, vec2(xcoord,  ((vTextureCoord.y ))*1.03 - parallaxBottom)- 0.02, 0.0 );
   }

   vec4 hawaiiFrameTextureColor;
   hawaiiFrameTextureColor = texture(frameTexture, vTextureCoord);
   if(hawaiiFrameTextureColor.g >hawaiiFrameTextureColor.r*1.3){
      hawaiiFrameTextureColor.a = 1.0 - hawaiiFrameTextureColor.g;
      hawaiiFrameTextureColor.g = 0.0;
      hawaiiFrameTextureColor.r = 0.0;
      hawaiiFrameTextureColor.b = 0.0;
   }
   mediump vec4 processedColor;
   processedColor.rgb = hawaiiFrameTextureColor.rgb + colorIn.rgb * colorIn.a * (1.0 - hawaiiFrameTextureColor.a);
   //processedColor.g = hawaiiFrameTextureColor.g + colorIn.g * colorIn.a * (1.0 - hawaiiFrameTextureColor.a);
   //processedColor.b = hawaiiFrameTextureColor.b + colorIn.b * colorIn.a * (1.0 - hawaiiFrameTextureColor.a);
   processedColor.a = hawaiiFrameTextureColor.a + colorIn.a * (1.0 - hawaiiFrameTextureColor.a);
   return processedColor;
}