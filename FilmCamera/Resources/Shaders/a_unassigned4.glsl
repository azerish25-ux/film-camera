uniform sampler2D frameSuper16mm;
uniform sampler2D mTextureID1;
uniform sampler2D mTextureID2;
vec4 frame(){
   vec4 colorIn;
   
   highp float xcoord;
   xcoord = (vTextureCoord.x )*1.03 - 0.02;

   
   if( ( vTextureCoord.y  > 0.03 && vTextureCoord.y  <0.985)){
      colorIn = textureLod(mTextureID1, vec2(xcoord / 1.03,  (vTextureCoord.y ))*1.03 - 0.02, 0.0 );
   } else if( vTextureCoord.y  < 0.03 ){
      colorIn = textureLod(mTextureID2, vec2(xcoord,  ((vTextureCoord.y ))*1.03 +0.980)- 0.02 , 0.0 );
   } else if( vTextureCoord.y  > 0.985 ){
      colorIn = textureLod(mTextureID, vec2(xcoord,  ((vTextureCoord.y ))*1.03 -0.980)- 0.02 , 0.0);
   }

   vec4 hawaiiFrameTextureColor;
   hawaiiFrameTextureColor = textureLod(frameSuper16mm, vTextureCoord, 0.0);
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