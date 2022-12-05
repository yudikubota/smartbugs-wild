{{
  "language": "Solidity",
  "sources": {
    "contracts/BANK.sol": {
      "content": "
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: In Mfer We Trust
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                             //
//                                                                                                                                                             //
//                                                                                                                                                             //
//                                                                                                                                                             //
//    ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,    //
//    ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,    //
//    ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,    //
//    ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,    //
//    ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,    //
//    ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,    //
//    ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,    //
//    ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,    //
//    ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,    //
//    ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,    //
//    ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,    //
//    ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,    //
//    ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,    //
//    ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,    //
//    ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,:,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,    //
//    ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,:,:;1fCmr}l:::!|mh*aZ/!:::,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,    //
//    ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,lroW%oh%B%MqYhW@B%%M#B8C!::,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,    //
//    ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,::::,:::,:u#B&b)I::!t*@@@MXi;:iY%B8XI,:,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,    //
//    ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,::::>jk%%oBBt:IYM88bZZoJ_IZB%BBZl:,,:,)a%b/::,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,    //
//    ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,:::;YW8&@@$$$$@mW%@%#hhha*8@@BakMwt;:,:::08Bpi:,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,    //
//    ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,:::>(*@B##%BB@$$$@88B@WW%%BB%@@@BW8@@B*8&YI;rM@#+,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,    //
//    ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,:::::ludB@@@@@W&###B@$@oa%BhLCJcuvZWBMqwoB@@B%%%%%Ma&af:,:,,:,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,    //
//    ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,:,,!jM@@@@@@$@@B####B@$@k*@%0UJvvCmW@BhJJXb%&LCbM%%B@@@L;:::,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,    //
//    ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,::::loB@@B&Ob@%&%####B@@@BkW8MOCLLLLp8@80LLC*B8LzCCUUkB@@@%%b>::,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,    //
//    ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,:::::-&B@@#OCLM#&##B@8#M@@@W*B%oQCUJCJp8%8LCJLoBBwUzzXUd&@8@@B%80l:,:,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,    //
//    ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,:,,::)*@@@W0LLLL#M@B@@@B#W$@@#a#880CUUCCd8B%ZLLLo8&qCLJCCqM%%h0khhh%W|i:,:,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,    //
//    ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,:,::!J%@@BqLQCJLQMM@$@%@M#M$@@#wqM8MOLCCLo#MqLJJXwM%ZLLJCLaB@%kwaBB8W8Mh|:::,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,    //
//    ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,::C%@@@8LLLUCLCL%##8@@@M#&@@$@@@%phpQQLCCQLXJCYC0wb0LLCCbB@@$B8&M&W8#B&hpi,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,    //
//    ,,,,,,,,,,,,,,,,,,,,,,,,,,::::,::+kB@@@*LObWW*wQh@@@@WBB#MB@$@bk8@@%#8oJLLJJJLLLLLCJJZ8@@@8**&BB%B@@@@@@@8a-::,,,,,,,,,,::;]xJf;::,,,,,,,,,,,,,,,,,,,    //
//    ,,,,,,,,,,,,,,,,,,,,,,,:::!>>?[><k@@B8mq&%%%%%8a8@@@BM@@BB@@$BW%%@8dZ%MZCCJCJYJLYz0M@@B%%B@ozMqzCx1~lI1p@%#ZI:,:,,,,,,,,:1Waq)U0:,,,,,,,,,,,,,,,,,,,,    //
//    ,,,,,,,,,,,,,,,,,,,,,:,;~tm#h&W%@@@@@8B&%*QUXq&B%@@@BM@W#B@@@&*MkW@k0**oXvJYuuucmB@B8@B*Zc!IIIIIIIIIIII!kB%Bf::,,,,,,,,,::::{hoZ:::,,,,,,,,,,,,,,,,,,    //
//    ,,,,,,,,,,,,,,,,,,,,,,_YpoWaLnM@@@%#dB@@%*QULh@BB$$@8@@@%&B$@BWWo8%dZ8BoCzvvYwk#B@$@BMC<IlIIIIIIIIIIIIIIcM&B*l::,,,,,,,:,,::~aMO:,:,,,,,,,,,,,,,,,,,,    //
//    ,,,,,,,,,,,,,,,,,,,::lUwk&L<IX@@@@%qWB%B%M*ZCQ&@@@@@$$@@B@@@$@@@@@Bqh@%0uvzOOaB@@@@a<IIIIIIIIlIIlIIllIII>##%B(::::,,,,,,,,,,U*or:,,:,,,,,,,,,,,,,,,,,    //
//    ,,,,,,,,,,,,,,,,,,,:IJ&*wf!:i#@@@@8k%B%%@Bbd*%@@@B@@8W@@W&M#M%@@B@@B8&wJUUCXq@B@MbplIIIIi1vZM@@@B*@@@@@@@@@@@8oBv;:,,,,,,,:;d#kl,,,,,,,,,,,,,,,,,,,,,    //
//    ,,,,,,,,,,,,,,,,,,::}aBh};,:c8@@8B@BaMk8%WM8@@@B8%@@@@@@8W@%##M8@@@@@B&aYCJXdBkoax[Z#B@$$$$@@@@@@@@#UxXUYYOq#B@@@X,,,,,::::ua*Z<:::,,,,,,,,,,,,,,,,,,    //
//    ,,,,,,,,,,,,,,,,,::!/h8j:,:io@@&aW@BZQQ&8W%@@@MM@@@WW@@%B%@B#####M@$$@@&Wpz0B8k%@@@@@@8hj""^.   ....;II:^'.   :@@C::,,,:::;hWk~I*i:,,,,,,,,,,,,,,,,,,    //
//    ,,,,,,,,,,,,,,,,,,:?dWdt,,:|a@BM*8BMpLChM%@@@M%@@@@@@8#%@@@@8#####M@$$@@@&kZB@8a@@).. .^I~[(tjxrxl^pdddddddm, I@@v:,,,,:::>h*m:l*-:,,,,,,,,,,,,,,,,,,    //
//    ,,,,,,,,,,,,,,,,,,:!v#8r,,:}&@@&h&@BkJvJw&@$@B$$@@@@@8@@8@@@@######8@@$@@@8dbB%aB@M'~xxY0QJUXvrxxi'qqmdkkkbp> I@@b:,,,,:,,Ihoapxh!,,,,,,,,,,,,,,,,,,,    //
//    ,,,,,,,,,,,,,,,,:::_nM#n:,:>w@@@ka8%wXCJq&@@$@@@@@B@@@%B@%8@@&M#####8@@@@@B&@@BbL&@j./rrcJJUUUXYul'0pddddddp< ?@@c:,,,,:::,;OhthY:::,,,,,,,,,,,,,,,,,    //
//    ,,,,,,,,,,,,,,,,,,::!pMp!,,:?%@@qmo*OLLCb%@@$$$@@@B@@@@@@@@@@@M####%@BB@@@%b}'   [@@;;xz0OOZZZOOYl.QhhhhhhhdI )@&!:,,,,,,,,:qpzbI::,,,,,,,,,,,,,,,,,,    //
//    ,,,,,,,,,,,,,,,,,,,,,!!!:::,]%@@CCLCCJUYp@@@$@$@@@@@@@@@@@@@@@WWBBM#B@%B@@%Y     '#@0.~xYZZZZOZZCi.Ohhhhhhhd; C@Wl:,,,,,,,:::)Cwbhu:,,,,,,,,,,,,,,,,,    //
//    ,,,,,,,,,,,,,,,,,,,,,,,,,,,:1%@@JJCCCYXza@@@$$@@@@@@@@@@@@@@@@%%M@8%$$%B@@@z  `(bB@@@? `/cvxxxjffi+UY(({|1}_..b@o;:,,,,,,,,::,:>Oh/:,,,,,,,,,,,,,,,,,    //
//    ,,,,,,,,,,,,,,,,,,,,,,,,,,,,(@@BUzCCCzCL*8B@$$$@@@@@@@@@@@@@@@8M%B@@$$@@@@8h&@@@@@@@@&!     ..-mpddddZ]''`l>-{o@&i,,,,,,,,,,:IwhQ!,:,,,,,,,,,,,,,,,,,    //
//    ,,,,,,,,,,,,,,,,,,,,,,,,,,,:j@@@UvYCCLCU*%B@$@$@@@@@@@@@@@@@@BW@@@B@$@@$@BW@%opo@B&+#@@@@@@@Bhddbdbbddk*B@@@@@@@M>:,,,,,,,::::;!::::,,,,,,,,,,,,,,,,,    //
//    ,,,,,,,,,,,,,,,,,,,,,,,,,,,:nB@B*zJCCUJCd8@@@$$$@@@@@@@@@@@@@@@@@@@@$@@@@8pCOd&@MwII<Op0Xcj/CddddddbdddZ-IIl*B@B%c::,,,,,,,,::,:,:,,,,,,,,,,,,,,,,,,,    //
//    ,,,,,,,,,,,,,,,,,,,,,,,,,,,:!8B@8#YCLJvvJwBBB@@BB@@@%@@@@@B@@8%@$$@@@@@@&LmkM%8d-;I;IIII;II!Lbdbdddddddm{;I|a*#%m:::,,,:,:,:::,:,,:::,,,,,,,,,,,,,,,,    //
//    ,,,,,,,,,,,,,,,,,,,,,,,,,,,:ro#@BhOCLUvuccYbWB@@$$$$$$@$@$@B@$B&B$@@@@@ozwa#BM)II;;;IIIIIIIIfpddddddddwjI;IQ*W&W-::,,,,,:I?vZdo#W#aO-:,,,,,,,,,,,,,,,    //
//    ,,,,,,,,,,,,,,,,,,,,,,,,,,,:_)IXB@hZCYUcXUvuXMB@@@@@@@@@BMWM&W8B@@@@BBmuO#%%UIIIIIIIIIIIIIIII![CLpdpO|lI;IIa%M%/:,:,,,,:O@@$$$$$$$$@@j,,,,,,,,,,,,,,,    //
//    ,,,,,,,,,,,,,,,,,,,,,,,,,,,,::::dB@BWXCLCcvYCCp&8@@@@@B@@@BB%%%B@@@8mLXCb%B/IIIIIIIIIIIIIIIIIIIIIIIIIIIIIlL%%%Q();:,,,::z@@$$$$@@$$@@|::,,,,,,,,,,,,,    //
//    ,,,,,,,,,,,,,,,,,,,,,,,,,,,,:,,:idM@%kCXXCCXJCCXZM&&8%@@@BBB@@B8mLQCUJCC&@dIIIIIIIIlItO>](f)+}/XQvrnC0ZmZpBB%@$@@&O!::::1@@@$$$@%@$@@|,:,,,,,,,,,,,,,    //
//    :,,,,,,,,,,,,,,,,,,,,,,,,,,,,,:::<kM@@@8dJCJCCJJLCLLQXYJJCYCCUUCLCLJzUCQB@ZIIIIIIIIIhB@@@@@@@@@@@@@@@@@@@@%8%@$@@@@Bh[I::Q@@$$$$$$$$M;:,,,,,,,,,,,,,,    //
//    :,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,::!ZaB%&MpCLLCLLLLLLLCYCJLLLLCLLJUCJUCCYq@BUIIII;IIra8@@@@@@@@@@@@@@@@%@B@@&an1|ZB@@@@Bo*B@$$$$$$$@@m::,,,,,,,,,,,,,,    //
//    ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,:,:j%@@B%aLQLLLCLCCLLYYYLLLCLJJLLLLUCJJYd@@M[IIIIIIII/LpZX|-!IIIIII]8@@@Bpf:::,,:+k@@@@@B@$$@@B@$$@C::,,,,,,,,,,,,,,    //
//    ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,:::,:<aB@WM%pLULCUXCCLYJCJLQLLLLCCLLCCCLCU0kB@WajIIIIIIIIIIIIIIIII?qh8@%8-::,::,,,,::<XMB@@@@@88B@@aI:::,,,,,,,,,,,,,    //
//    ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,:::-0*&B&@@@@B&wUCUUCLCLLLQLLCCLLLLLLCUJCCzvUk@@@ot}<IIIIIIIIIl~ZWW8BBht!::,,,,,,,,,::,:!{L*%B@B@%j:::,,,,,,,,,,,,,,,    //
//    ,,,,,,,,,,,,,,,,,,,,,,,,,,,:,,::-#@%8%&%8%MW8@@@MkQLLJCLLzXJCLLLLLLLLCLLCLLLCJcOM@@B&r__ll!!-nh8@@@B*!:::::,,,,,,,,,,,,:,,:,:>_;I:::,,,,,,,,,,,,,,,,,    //
//    ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,:X%%*M8%8&#&W/XM&8B@MpmJYYCCCLLLLCLLCCLLLLYCLLCCCJzUd@@@%8hB@@BB@@@%L;:::,,,,,,,,,,,,,,,,,,,:,,,,,,,,,,,,,,,,,,,,,,,,,,    //
//    ,,,,,,,,,,,,,,,,,,,,,,,,,,,,:,:<*BW#&BB%o*Mo|:Iro%BB%WaZUzJCLJYCCYUCCXvzUCYzCCCCCJJUC#BB%WW%@@aLi::::::,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,    //
//    ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,:[WB%%8@%#o&o#),::IUbb%@%Mahh0JJUCLCJJCYYCJYXvvcvvcQ#%%B%Bamx_i:,::,,,,,,,,,,,,,,,,,,,,,,,,,:::liI::,:,,,,,,,,,,,,,,,,    //
//    ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,:1BB@m&B&&oo*U:::,:::?aM*aa*%@@B&#ohbqJxYZmbdk#&B@@B%&U+::::,,::,,,,,,,,,,,:,,,,,,,,,,,:,,,:0at}/m&[,:::,,,,,,,,,,,,,    //
//    ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,:f@B@8@&8W*aa):,,,:::,:-Qwbbh#&%B@@@@@@B#8%%%@@%w{;,::,,,,,,,,,,,,,,,,,:,:,::::::::::::::;t8*ddMtcZ,:,,,::,:,,:::;;:    //
//    ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,:::v@B@%B%8#aah+,,,,:,,,::::,::>)cf)cwa*B@@M&%*b[::,,:,,,,,,,,,,,,,:,:,,:-()||~<}rt}+~(f>[8?:>[]I;Y&[;l<{tnJQpaaM%B@B    //
//    ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,:,:J%&&MB%8*oab:::,,,:,,,,,,,,,,,,,::::{#%8*&Yl::::,:,,,,,,,,,,,,,:,:?o@@@$$$$$$$$$$$@#kMl"YMLuWv:cX@%%B%&&&&8%%BBB%    //
//    ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,::YB8#8@&%*&ahI:::,,,,,,,,,,,,,,,,,,,,!q&%%al::,,,,,,,,,,,,,:,:IfZB@@@@@$$$$$$$$$$$@@@&!Ik8B|)ZljXo%888888W#hwZQYn    //
//    ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,:,:vB*#BBMooMWU::,,,,,,,,,,,,,,,,,,,,,:>oBB%b+<!;i+|)l:::::<d##@@@$$$@Wa##khaha#b8$@B%BoIl(YZj,IkY1>ii!l,,,,,,:,,:    //
//    ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,:::xB8*%MMaaMM(:,,,,,,,,,,,,,,,,,,,,,::{%@@@@@@@@@@@&@@@@@@@@@@@8#*hMkM&MWMWWMabh$$@&-#}hc1[zbB|:,,:::,:,,,,,,,,,    //
//    ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,:YBB*%#&o88W-::,,,,,,,,,,,,,,:,,::|k8@$$$$$$$$$$@@@$$$@$$$@@&MMM&Wabk*#*ahoW%@$@@o~%n]!Il_j&-:::::,::,::::l_{t    //
//    ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,:;p@W8%M&&88ol:,,,,,,,,,,,,,,,::iW@@@$$BhbkM@$$$$$$@$$$$$@Mkb*W&##&B@$$$$$$$$$$@@@#ui~|vr/tzr|{>l-xOhho*M&BBBB    //
//    ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,:i&B8%8&MB8&p::,,,,,,,,,,:::+f8@@B%$$8kakbbbkoB$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$@@@@BB%BBB@@BBB@BBB@@BB@@@@@B    //
//    ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,:-%BW&%%%%W#L::,,,,,,,,::~M@@@@Mhb%$$@ookkbbbbh#B$$$$$$$$$$$$$$$$$$$$$$$@B&##WB$$$@@B%8&&8%BBB@@@B%oQr[<!;::    //
//    ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,;k88MoaWB%%*I::,,,,,,::J@@$@@oMoo@@@@@*bboabhbbbbbbbbbbbbbbo&&#abbbbbbbbbbbbbbM@$@@8ohq0c/~::,,:,:::,,,,,,,    //
//    ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,::Lo&%#a#8BBc::,,,,,,:l%@@@*oM#kMWB@@$$@B8Mokookbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbk*$@@%[:::,,:,,,,,,,,,,,,,,,,    //
//    ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,:xaWBWaWB@@O;:,,,,,,|@@@WaW#bk@@@@@@$$$@@@@@@888*haabkakhakbbbbbk*o#&%B@%#@$@@@@@@Q:::,,,,,,,,,,,,,,,,,,,    //
//    ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,::)ak%8#8@B@d!::,,,:v@@@h#obbbB@$@@B@$W$$$$$$$$$$$$$$$$$$$$$$$$$$$$@@@@@@@@%8888BBa},:,,,,,,,,,,,,,,,,,,,    //
//    ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,:,,:uakW8BB@%@&t:,,,,n@@@hM#kbbW@@C(%@$$$88@$$$$$$$$$$$$$$$$$$$$$$@@M0r([?>;:::,::,:,:,:,,,,,,,,,,,,,,,,,,    //
//    ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,:>hh*%8BBB%@Bq::,:}@@@oW*hbb#$@v:~&@@@$&ba*bbbbbbkbkkkbbbb#$@$$$$@8O)<;:,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,    //
//    ,,,,,,,,,:,,:,,,:,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,:;pBB*B%B%%Bb;,:~@@BkMMbbbo@@J::IC@@@@BhaMMhhk*kbbbbbbbbbkW@$$$@@@@@@X::,,::,::,,,,,,,,:,,,,,,,,,,,,,    //
//    ,,,,C~ti::,::;?;::::,,,,,,,,,,,,,,,,,,,,,,,,,,,,,::m@8aB@BB&@a;:l@@@WMMbbbh@@*:::::!#@@@@oaoMhMa*bbbbbbbbbbbbbbW$$@@@@@@&|:::,:,,,,,,,,,,,,,,::,,,,,,    //
//    ,,:;/Itn:t|j/}r0|f{::,,,,,,,,,,,,,,,,,,,,,,,,,,::,:;Z@8h&@@B%BdI;M@$8W#bbbo@@8>:,:,::~0%@@@@B*ko*Moo#kbbbbbbbbbbbbaW@@@@@@@8v!:::::::::I]l:I_<>:lI:,,    //
//    ,::>1-~?<<llI>~!!~:::,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,::|B%*M%@88%w!B@@8#hbbbM$@@),,,,:,:,:IJB@$$@*bkk#bbhhkbbbbbbbbbbbbh%@@$$@@@p;_|{-<i::Ii-l+~Ii+:::,    //
//                                                                                                                                                             //
//                                                                                                                                                             //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract BANK is ERC721Creator {
    constructor() ERC721Creator("In Mfer We Trust", "BANK") {}
}
"
    },
    "contracts/ERC721Creator.sol": {
      "content": "
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/proxy/Proxy.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";

contract ERC721Creator is Proxy {
    
    constructor(string memory name, string memory symbol) {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = 0xe4E4003afE3765Aca8149a82fc064C0b125B9e5a;
        Address.functionDelegateCall(
            0xe4E4003afE3765Aca8149a82fc064C0b125B9e5a,
            abi.encodeWithSignature("initialize(string,string)", name, symbol)
        );
    }
        
    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Returns the current implementation address.
     */
     function implementation() public view returns (address) {
        return _implementation();
    }

    function _implementation() internal override view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }    

}
"
    },
    "@openzeppelin/contracts/proxy/Proxy.sol": {
      "content": "// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/Proxy.sol)

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overriden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}
"
    },
    "@openzeppelin/contracts/utils/Address.sol": {
      "content": "// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}
"
    },
    "@openzeppelin/contracts/utils/StorageSlot.sol": {
      "content": "// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}
"
    }
  },
  "settings": {
    "optimizer": {
      "enabled": true,
      "runs": 300
    },
    "outputSelection": {
      "*": {
        "*": [
          "evm.bytecode",
          "evm.deployedBytecode",
          "devdoc",
          "userdoc",
          "metadata",
          "abi"
        ]
      }
    },
    "libraries": {}
  }
}}