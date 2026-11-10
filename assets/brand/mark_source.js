// 칼로리스냅 로고 (1024 그리드). 주황 배경 + 흰 뷰파인더 + 웃는 밥그릇 + 반짝이.
const ORANGE='#FF7A2F';
const spark=(x,y,r,c)=>{const k=.16;return `<path fill="${c}" d="M${x} ${y-r} C${x+r*k} ${y-r*k} ${x+r*k} ${y-r*k} ${x+r} ${y} C${x+r*k} ${y+r*k} ${x+r*k} ${y+r*k} ${x} ${y+r} C${x-r*k} ${y+r*k} ${x-r*k} ${y+r*k} ${x-r} ${y} C${x-r*k} ${y-r*k} ${x-r*k} ${y-r*k} ${x} ${y-r}Z"/>`};
const corners=(c,w=40,i=200,l=110,rr=34)=>{const a=i,b=1024-i;return `<g fill="none" stroke="${c}" stroke-width="${w}" stroke-linecap="round" stroke-linejoin="round"><path d="M${a} ${a+l} V${a+rr} Q${a} ${a} ${a+rr} ${a} H${a+l}"/><path d="M${b-l} ${a} H${b-rr} Q${b} ${a} ${b} ${a+rr} V${a+l}"/><path d="M${a} ${b-l} V${b-rr} Q${a} ${b} ${a+rr} ${b} H${a+l}"/><path d="M${b-l} ${b} H${b-rr} Q${b} ${b} ${b} ${b-rr} V${b-l}"/></g>`};
const bowl=(c)=>`<g fill="${c}"><path d="M292 534 H732 A220 196 0 0 1 512 730 A220 196 0 0 1 292 534Z"/><path d="M340 506 C352 414 430 378 512 378 C594 378 672 414 684 506Z"/><rect x="448" y="738" width="128" height="34" rx="17"/></g>`;
const face=(c)=>`<g fill="${c}"><circle cx="440" cy="606" r="22"/><circle cx="584" cy="606" r="22"/><path d="M470 656 Q512 694 554 656" stroke="${c}" stroke-width="18" fill="none" stroke-linecap="round"/></g><g fill="#FFB38A"><ellipse cx="392" cy="646" rx="26" ry="16"/><ellipse cx="632" cy="646" rx="26" ry="16"/></g>`;
const DEFS=`<defs><linearGradient id="og" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#FF9A52"/><stop offset="1" stop-color="#FF6A1F"/></linearGradient></defs>`;
const MARK=(withBg=true, ink='#fff')=>DEFS+(withBg?`<rect width="1024" height="1024" fill="url(#og)"/>`:'')
  +corners(ink)+bowl(ink)+face(ORANGE)+spark(726,320,60,'#FFE066');
