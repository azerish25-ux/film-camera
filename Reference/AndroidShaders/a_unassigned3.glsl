uniform samplerExternalOES frameTexture;
vec4 frame(){
   vec4 colorIn;
   
   highp float xcoord;
   xcoord = (vTextureCoord.x ) - 0.07;
                                 
   if(vTextureCoord.x  > 0.16){
      colorIn = textureLod(mTextureID, vec2(xcoord,  vTextureCoord.y ), 0.0 );
   } else {
       colorIn = textureLod(mTextureID, vec2(0.0,  vTextureCoord.y ), 0.0 );
   }

   vec4 frameTextureColor;
   frameTextureColor = texture(frameTexture, vTextureCoord);
   
   if(vTextureCoord.x  > 0.16 && frameTextureColor.g >frameTextureColor.r*1.3){
      frameTextureColor.a = 1.0 - clamp(frameTextureColor.g * 1.3, 0.0, 1.0);
      frameTextureColor.g = 0.0;
      frameTextureColor.r = 0.0;
      frameTextureColor.b = 0.0;
   } else if(vTextureCoord.x  < 0.16 && frameTextureColor.g >frameTextureColor.r*1.3){
      frameTextureColor.a = 1.0;
      frameTextureColor.g = frameTextureColor.r;
   }else if(vTextureCoord.x  > 0.15 && vTextureCoord.x  < 0.18 && vTextureCoord.y  > 0.4 && vTextureCoord.y  < 0.6 && frameTextureColor.r >frameTextureColor.b*1.3){
      frameTextureColor.a = 1.0;
      frameTextureColor.r = frameTextureColor.g;     
   }
   
   
   mediump vec4 processedColor;
   if(vTextureCoord.x < 0.97 ){
        processedColor.rgb = frameTextureColor.rgb + colorIn.rgb * colorIn.a * (1.0 - frameTextureColor.a);
        //processedColor.g = frameTextureColor.g + colorIn.g * colorIn.a * (1.0 - frameTextureColor.a);
        //processedColor.b = frameTextureColor.b + colorIn.b * colorIn.a * (1.0 - frameTextureColor.a);
        processedColor.a = frameTextureColor.a + colorIn.a * (1.0 - frameTextureColor.a);
   } else {
        processedColor = vec4(0.0,0.0,0.0,1.0);
   }   
   return processedColor;
}