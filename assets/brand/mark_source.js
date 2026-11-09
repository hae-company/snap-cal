// 1024 그리드 로고 마크. 앱 아이콘, 스플래시, Flutter 페인터 모두 이 좌표를 쓴다.
const spark=(x,y,r,c)=>{const k=.16;return `<path fill="${c}" d="M${x} ${y-r} C${x+r*k} ${y-r*k} ${x+r*k} ${y-r*k} ${x+r} ${y} C${x+r*k} ${y+r*k} ${x+r*k} ${y+r*k} ${x} ${y+r} C${x-r*k} ${y+r*k} ${x-r*k} ${y+r*k} ${x-r} ${y} C${x-r*k} ${y-r*k} ${x-r*k} ${y-r*k} ${x} ${y-r}Z"/>`};
const corners=(c,i=196,l=124,w=48,rr=34)=>{const a=i,b=1024-i;return `<g fill="none" stroke="${c}" stroke-width="${w}" stroke-linecap="round" stroke-linejoin="round">
<path d="M${a} ${a+l} V${a+rr} Q${a} ${a} ${a+rr} ${a} H${a+l}"/><path d="M${b-l} ${a} H${b-rr} Q${b} ${a} ${b} ${a+rr} V${a+l}"/><path d="M${a} ${b-l} V${b-rr} Q${a} ${b} ${a+rr} ${b} H${a+l}"/><path d="M${b-l} ${b} H${b-rr} Q${b} ${b} ${b} ${b-rr} V${b-l}"/></g>`};
const bowl=(c)=>`<g fill="${c}">
<path d="M292 540 H732 A220 196 0 0 1 512 736 A220 196 0 0 1 292 540Z"/>
<path d="M340 512 C352 420 430 384 512 384 C594 384 672 420 684 512Z"/>
<rect x="448" y="744" width="128" height="34" rx="17"/></g>`;
const DEFS=`<defs><linearGradient id="bg" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#1C2026"/><stop offset="1" stop-color="#0A0C0E"/></linearGradient>
<linearGradient id="gr" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#6CF5B4"/><stop offset="1" stop-color="#12B76A"/></linearGradient>
<radialGradient id="glow" cx=".5" cy=".55" r=".5"><stop offset="0" stop-color="#12B76A" stop-opacity=".22"/><stop offset="1" stop-color="#12B76A" stop-opacity="0"/></radialGradient></defs>`;
const MARK=(withBg=true)=>DEFS+(withBg?`<rect width="1024" height="1024" fill="url(#bg)"/><rect width="1024" height="1024" fill="url(#glow)"/>`:'')
 +corners('url(#gr)')+bowl('#fff')+spark(712,318,92,'#FFD84D')+spark(596,250,34,'#6CF5B4');
