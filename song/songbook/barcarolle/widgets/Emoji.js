.pragma library

// Unicode emoji-test.txt 17.0, fully-qualified, no skin-tone variants,
// no Component group, E<=16.0 and present in Noto Color Emoji 2.051.
// folders: the Unicode groups in CLDR order, each with the emblem drawn on its folder icon.
// raw: one line per emoji: glyph TAB name TAB subgroup words TAB group key.

var folders = [
{ "key": "smileys", "name": "Smileys & Emotion", "emblem": "😀" },
{ "key": "people", "name": "People & Body", "emblem": "🧑" },
{ "key": "animals", "name": "Animals & Nature", "emblem": "🐱" },
{ "key": "food", "name": "Food & Drink", "emblem": "🍙" },
{ "key": "travel", "name": "Travel & Places", "emblem": "✈️" },
{ "key": "activities", "name": "Activities", "emblem": "⚽" },
{ "key": "objects", "name": "Objects", "emblem": "💡" },
{ "key": "symbols", "name": "Symbols", "emblem": "❤️" },
{ "key": "flags", "name": "Flags", "emblem": "🏁" }
]

var raw = `😀	grinning face	face smiling	smileys
😃	grinning face with big eyes	face smiling	smileys
😄	grinning face with smiling eyes	face smiling	smileys
😁	beaming face with smiling eyes	face smiling	smileys
😆	grinning squinting face	face smiling	smileys
😅	grinning face with sweat	face smiling	smileys
🤣	rolling on the floor laughing	face smiling	smileys
😂	face with tears of joy	face smiling	smileys
🙂	slightly smiling face	face smiling	smileys
🙃	upside-down face	face smiling	smileys
🫠	melting face	face smiling	smileys
😉	winking face	face smiling	smileys
😊	smiling face with smiling eyes	face smiling	smileys
😇	smiling face with halo	face smiling	smileys
🥰	smiling face with hearts	face affection	smileys
😍	smiling face with heart-eyes	face affection	smileys
🤩	star-struck	face affection	smileys
😘	face blowing a kiss	face affection	smileys
😗	kissing face	face affection	smileys
☺️	smiling face	face affection	smileys
😚	kissing face with closed eyes	face affection	smileys
😙	kissing face with smiling eyes	face affection	smileys
🥲	smiling face with tear	face affection	smileys
😋	face savoring food	face tongue	smileys
😛	face with tongue	face tongue	smileys
😜	winking face with tongue	face tongue	smileys
🤪	zany face	face tongue	smileys
😝	squinting face with tongue	face tongue	smileys
🤑	money-mouth face	face tongue	smileys
🤗	smiling face with open hands	face hand	smileys
🤭	face with hand over mouth	face hand	smileys
🫢	face with open eyes and hand over mouth	face hand	smileys
🫣	face with peeking eye	face hand	smileys
🤫	shushing face	face hand	smileys
🤔	thinking face	face hand	smileys
🫡	saluting face	face hand	smileys
🤐	zipper-mouth face	face neutral skeptical	smileys
🤨	face with raised eyebrow	face neutral skeptical	smileys
😐	neutral face	face neutral skeptical	smileys
😑	expressionless face	face neutral skeptical	smileys
😶	face without mouth	face neutral skeptical	smileys
🫥	dotted line face	face neutral skeptical	smileys
😶‍🌫️	face in clouds	face neutral skeptical	smileys
😏	smirking face	face neutral skeptical	smileys
😒	unamused face	face neutral skeptical	smileys
🙄	face with rolling eyes	face neutral skeptical	smileys
😬	grimacing face	face neutral skeptical	smileys
😮‍💨	face exhaling	face neutral skeptical	smileys
🤥	lying face	face neutral skeptical	smileys
🫨	shaking face	face neutral skeptical	smileys
🙂‍↔️	head shaking horizontally	face neutral skeptical	smileys
🙂‍↕️	head shaking vertically	face neutral skeptical	smileys
😌	relieved face	face sleepy	smileys
😔	pensive face	face sleepy	smileys
😪	sleepy face	face sleepy	smileys
🤤	drooling face	face sleepy	smileys
😴	sleeping face	face sleepy	smileys
🫩	face with bags under eyes	face sleepy	smileys
😷	face with medical mask	face unwell	smileys
🤒	face with thermometer	face unwell	smileys
🤕	face with head-bandage	face unwell	smileys
🤢	nauseated face	face unwell	smileys
🤮	face vomiting	face unwell	smileys
🤧	sneezing face	face unwell	smileys
🥵	hot face	face unwell	smileys
🥶	cold face	face unwell	smileys
🥴	woozy face	face unwell	smileys
😵	face with crossed-out eyes	face unwell	smileys
😵‍💫	face with spiral eyes	face unwell	smileys
🤯	exploding head	face unwell	smileys
🤠	cowboy hat face	face hat	smileys
🥳	partying face	face hat	smileys
🥸	disguised face	face hat	smileys
😎	smiling face with sunglasses	face glasses	smileys
🤓	nerd face	face glasses	smileys
🧐	face with monocle	face glasses	smileys
😕	confused face	face concerned	smileys
🫤	face with diagonal mouth	face concerned	smileys
😟	worried face	face concerned	smileys
🙁	slightly frowning face	face concerned	smileys
☹️	frowning face	face concerned	smileys
😮	face with open mouth	face concerned	smileys
😯	hushed face	face concerned	smileys
😲	astonished face	face concerned	smileys
😳	flushed face	face concerned	smileys
🥺	pleading face	face concerned	smileys
🥹	face holding back tears	face concerned	smileys
😦	frowning face with open mouth	face concerned	smileys
😧	anguished face	face concerned	smileys
😨	fearful face	face concerned	smileys
😰	anxious face with sweat	face concerned	smileys
😥	sad but relieved face	face concerned	smileys
😢	crying face	face concerned	smileys
😭	loudly crying face	face concerned	smileys
😱	face screaming in fear	face concerned	smileys
😖	confounded face	face concerned	smileys
😣	persevering face	face concerned	smileys
😞	disappointed face	face concerned	smileys
😓	downcast face with sweat	face concerned	smileys
😩	weary face	face concerned	smileys
😫	tired face	face concerned	smileys
🥱	yawning face	face concerned	smileys
😤	face with steam from nose	face negative	smileys
😡	enraged face	face negative	smileys
😠	angry face	face negative	smileys
🤬	face with symbols on mouth	face negative	smileys
😈	smiling face with horns	face negative	smileys
👿	angry face with horns	face negative	smileys
💀	skull	face negative	smileys
☠️	skull and crossbones	face negative	smileys
💩	pile of poo	face costume	smileys
🤡	clown face	face costume	smileys
👹	ogre	face costume	smileys
👺	goblin	face costume	smileys
👻	ghost	face costume	smileys
👽	alien	face costume	smileys
👾	alien monster	face costume	smileys
🤖	robot	face costume	smileys
😺	grinning cat	cat face	smileys
😸	grinning cat with smiling eyes	cat face	smileys
😹	cat with tears of joy	cat face	smileys
😻	smiling cat with heart-eyes	cat face	smileys
😼	cat with wry smile	cat face	smileys
😽	kissing cat	cat face	smileys
🙀	weary cat	cat face	smileys
😿	crying cat	cat face	smileys
😾	pouting cat	cat face	smileys
🙈	see-no-evil monkey	monkey face	smileys
🙉	hear-no-evil monkey	monkey face	smileys
🙊	speak-no-evil monkey	monkey face	smileys
💌	love letter	heart	smileys
💘	heart with arrow	heart	smileys
💝	heart with ribbon	heart	smileys
💖	sparkling heart	heart	smileys
💗	growing heart	heart	smileys
💓	beating heart	heart	smileys
💞	revolving hearts	heart	smileys
💕	two hearts	heart	smileys
💟	heart decoration	heart	smileys
❣️	heart exclamation	heart	smileys
💔	broken heart	heart	smileys
❤️‍🔥	heart on fire	heart	smileys
❤️‍🩹	mending heart	heart	smileys
❤️	red heart	heart	smileys
🩷	pink heart	heart	smileys
🧡	orange heart	heart	smileys
💛	yellow heart	heart	smileys
💚	green heart	heart	smileys
💙	blue heart	heart	smileys
🩵	light blue heart	heart	smileys
💜	purple heart	heart	smileys
🤎	brown heart	heart	smileys
🖤	black heart	heart	smileys
🩶	grey heart	heart	smileys
🤍	white heart	heart	smileys
💋	kiss mark	emotion	smileys
💯	hundred points	emotion	smileys
💢	anger symbol	emotion	smileys
💥	collision	emotion	smileys
💫	dizzy	emotion	smileys
💦	sweat droplets	emotion	smileys
💨	dashing away	emotion	smileys
🕳️	hole	emotion	smileys
💬	speech balloon	emotion	smileys
👁️‍🗨️	eye in speech bubble	emotion	smileys
🗨️	left speech bubble	emotion	smileys
🗯️	right anger bubble	emotion	smileys
💭	thought balloon	emotion	smileys
💤	ZZZ	emotion	smileys
👋	waving hand	hand fingers open	people
🤚	raised back of hand	hand fingers open	people
🖐️	hand with fingers splayed	hand fingers open	people
✋	raised hand	hand fingers open	people
🖖	vulcan salute	hand fingers open	people
🫱	rightwards hand	hand fingers open	people
🫲	leftwards hand	hand fingers open	people
🫳	palm down hand	hand fingers open	people
🫴	palm up hand	hand fingers open	people
🫷	leftwards pushing hand	hand fingers open	people
🫸	rightwards pushing hand	hand fingers open	people
👌	OK hand	hand fingers partial	people
🤌	pinched fingers	hand fingers partial	people
🤏	pinching hand	hand fingers partial	people
✌️	victory hand	hand fingers partial	people
🤞	crossed fingers	hand fingers partial	people
🫰	hand with index finger and thumb crossed	hand fingers partial	people
🤟	love-you gesture	hand fingers partial	people
🤘	sign of the horns	hand fingers partial	people
🤙	call me hand	hand fingers partial	people
👈	backhand index pointing left	hand single finger	people
👉	backhand index pointing right	hand single finger	people
👆	backhand index pointing up	hand single finger	people
🖕	middle finger	hand single finger	people
👇	backhand index pointing down	hand single finger	people
☝️	index pointing up	hand single finger	people
🫵	index pointing at the viewer	hand single finger	people
👍	thumbs up	hand fingers closed	people
👎	thumbs down	hand fingers closed	people
✊	raised fist	hand fingers closed	people
👊	oncoming fist	hand fingers closed	people
🤛	left-facing fist	hand fingers closed	people
🤜	right-facing fist	hand fingers closed	people
👏	clapping hands	hands	people
🙌	raising hands	hands	people
🫶	heart hands	hands	people
👐	open hands	hands	people
🤲	palms up together	hands	people
🤝	handshake	hands	people
🙏	folded hands	hands	people
✍️	writing hand	hand prop	people
💅	nail polish	hand prop	people
🤳	selfie	hand prop	people
💪	flexed biceps	body parts	people
🦾	mechanical arm	body parts	people
🦿	mechanical leg	body parts	people
🦵	leg	body parts	people
🦶	foot	body parts	people
👂	ear	body parts	people
🦻	ear with hearing aid	body parts	people
👃	nose	body parts	people
🧠	brain	body parts	people
🫀	anatomical heart	body parts	people
🫁	lungs	body parts	people
🦷	tooth	body parts	people
🦴	bone	body parts	people
👀	eyes	body parts	people
👁️	eye	body parts	people
👅	tongue	body parts	people
👄	mouth	body parts	people
🫦	biting lip	body parts	people
👶	baby	person	people
🧒	child	person	people
👦	boy	person	people
👧	girl	person	people
🧑	person	person	people
👱	person: blond hair	person	people
👨	man	person	people
🧔	person: beard	person	people
🧔‍♂️	man: beard	person	people
🧔‍♀️	woman: beard	person	people
👨‍🦰	man: red hair	person	people
👨‍🦱	man: curly hair	person	people
👨‍🦳	man: white hair	person	people
👨‍🦲	man: bald	person	people
👩	woman	person	people
👩‍🦰	woman: red hair	person	people
🧑‍🦰	person: red hair	person	people
👩‍🦱	woman: curly hair	person	people
🧑‍🦱	person: curly hair	person	people
👩‍🦳	woman: white hair	person	people
🧑‍🦳	person: white hair	person	people
👩‍🦲	woman: bald	person	people
🧑‍🦲	person: bald	person	people
👱‍♀️	woman: blond hair	person	people
👱‍♂️	man: blond hair	person	people
🧓	older person	person	people
👴	old man	person	people
👵	old woman	person	people
🙍	person frowning	person gesture	people
🙍‍♂️	man frowning	person gesture	people
🙍‍♀️	woman frowning	person gesture	people
🙎	person pouting	person gesture	people
🙎‍♂️	man pouting	person gesture	people
🙎‍♀️	woman pouting	person gesture	people
🙅	person gesturing NO	person gesture	people
🙅‍♂️	man gesturing NO	person gesture	people
🙅‍♀️	woman gesturing NO	person gesture	people
🙆	person gesturing OK	person gesture	people
🙆‍♂️	man gesturing OK	person gesture	people
🙆‍♀️	woman gesturing OK	person gesture	people
💁	person tipping hand	person gesture	people
💁‍♂️	man tipping hand	person gesture	people
💁‍♀️	woman tipping hand	person gesture	people
🙋	person raising hand	person gesture	people
🙋‍♂️	man raising hand	person gesture	people
🙋‍♀️	woman raising hand	person gesture	people
🧏	deaf person	person gesture	people
🧏‍♂️	deaf man	person gesture	people
🧏‍♀️	deaf woman	person gesture	people
🙇	person bowing	person gesture	people
🙇‍♂️	man bowing	person gesture	people
🙇‍♀️	woman bowing	person gesture	people
🤦	person facepalming	person gesture	people
🤦‍♂️	man facepalming	person gesture	people
🤦‍♀️	woman facepalming	person gesture	people
🤷	person shrugging	person gesture	people
🤷‍♂️	man shrugging	person gesture	people
🤷‍♀️	woman shrugging	person gesture	people
🧑‍⚕️	health worker	person role	people
👨‍⚕️	man health worker	person role	people
👩‍⚕️	woman health worker	person role	people
🧑‍🎓	student	person role	people
👨‍🎓	man student	person role	people
👩‍🎓	woman student	person role	people
🧑‍🏫	teacher	person role	people
👨‍🏫	man teacher	person role	people
👩‍🏫	woman teacher	person role	people
🧑‍⚖️	judge	person role	people
👨‍⚖️	man judge	person role	people
👩‍⚖️	woman judge	person role	people
🧑‍🌾	farmer	person role	people
👨‍🌾	man farmer	person role	people
👩‍🌾	woman farmer	person role	people
🧑‍🍳	cook	person role	people
👨‍🍳	man cook	person role	people
👩‍🍳	woman cook	person role	people
🧑‍🔧	mechanic	person role	people
👨‍🔧	man mechanic	person role	people
👩‍🔧	woman mechanic	person role	people
🧑‍🏭	factory worker	person role	people
👨‍🏭	man factory worker	person role	people
👩‍🏭	woman factory worker	person role	people
🧑‍💼	office worker	person role	people
👨‍💼	man office worker	person role	people
👩‍💼	woman office worker	person role	people
🧑‍🔬	scientist	person role	people
👨‍🔬	man scientist	person role	people
👩‍🔬	woman scientist	person role	people
🧑‍💻	technologist	person role	people
👨‍💻	man technologist	person role	people
👩‍💻	woman technologist	person role	people
🧑‍🎤	singer	person role	people
👨‍🎤	man singer	person role	people
👩‍🎤	woman singer	person role	people
🧑‍🎨	artist	person role	people
👨‍🎨	man artist	person role	people
👩‍🎨	woman artist	person role	people
🧑‍✈️	pilot	person role	people
👨‍✈️	man pilot	person role	people
👩‍✈️	woman pilot	person role	people
🧑‍🚀	astronaut	person role	people
👨‍🚀	man astronaut	person role	people
👩‍🚀	woman astronaut	person role	people
🧑‍🚒	firefighter	person role	people
👨‍🚒	man firefighter	person role	people
👩‍🚒	woman firefighter	person role	people
👮	police officer	person role	people
👮‍♂️	man police officer	person role	people
👮‍♀️	woman police officer	person role	people
🕵️	detective	person role	people
🕵️‍♂️	man detective	person role	people
🕵️‍♀️	woman detective	person role	people
💂	guard	person role	people
💂‍♂️	man guard	person role	people
💂‍♀️	woman guard	person role	people
🥷	ninja	person role	people
👷	construction worker	person role	people
👷‍♂️	man construction worker	person role	people
👷‍♀️	woman construction worker	person role	people
🫅	person with crown	person role	people
🤴	prince	person role	people
👸	princess	person role	people
👳	person wearing turban	person role	people
👳‍♂️	man wearing turban	person role	people
👳‍♀️	woman wearing turban	person role	people
👲	person with skullcap	person role	people
🧕	woman with headscarf	person role	people
🤵	person in tuxedo	person role	people
🤵‍♂️	man in tuxedo	person role	people
🤵‍♀️	woman in tuxedo	person role	people
👰	person with veil	person role	people
👰‍♂️	man with veil	person role	people
👰‍♀️	woman with veil	person role	people
🤰	pregnant woman	person role	people
🫃	pregnant man	person role	people
🫄	pregnant person	person role	people
🤱	breast-feeding	person role	people
👩‍🍼	woman feeding baby	person role	people
👨‍🍼	man feeding baby	person role	people
🧑‍🍼	person feeding baby	person role	people
👼	baby angel	person fantasy	people
🎅	Santa Claus	person fantasy	people
🤶	Mrs. Claus	person fantasy	people
🧑‍🎄	Mx Claus	person fantasy	people
🦸	superhero	person fantasy	people
🦸‍♂️	man superhero	person fantasy	people
🦸‍♀️	woman superhero	person fantasy	people
🦹	supervillain	person fantasy	people
🦹‍♂️	man supervillain	person fantasy	people
🦹‍♀️	woman supervillain	person fantasy	people
🧙	mage	person fantasy	people
🧙‍♂️	man mage	person fantasy	people
🧙‍♀️	woman mage	person fantasy	people
🧚	fairy	person fantasy	people
🧚‍♂️	man fairy	person fantasy	people
🧚‍♀️	woman fairy	person fantasy	people
🧛	vampire	person fantasy	people
🧛‍♂️	man vampire	person fantasy	people
🧛‍♀️	woman vampire	person fantasy	people
🧜	merperson	person fantasy	people
🧜‍♂️	merman	person fantasy	people
🧜‍♀️	mermaid	person fantasy	people
🧝	elf	person fantasy	people
🧝‍♂️	man elf	person fantasy	people
🧝‍♀️	woman elf	person fantasy	people
🧞	genie	person fantasy	people
🧞‍♂️	man genie	person fantasy	people
🧞‍♀️	woman genie	person fantasy	people
🧟	zombie	person fantasy	people
🧟‍♂️	man zombie	person fantasy	people
🧟‍♀️	woman zombie	person fantasy	people
🧌	troll	person fantasy	people
💆	person getting massage	person activity	people
💆‍♂️	man getting massage	person activity	people
💆‍♀️	woman getting massage	person activity	people
💇	person getting haircut	person activity	people
💇‍♂️	man getting haircut	person activity	people
💇‍♀️	woman getting haircut	person activity	people
🚶	person walking	person activity	people
🚶‍♂️	man walking	person activity	people
🚶‍♀️	woman walking	person activity	people
🚶‍➡️	person walking facing right	person activity	people
🚶‍♀️‍➡️	woman walking facing right	person activity	people
🚶‍♂️‍➡️	man walking facing right	person activity	people
🧍	person standing	person activity	people
🧍‍♂️	man standing	person activity	people
🧍‍♀️	woman standing	person activity	people
🧎	person kneeling	person activity	people
🧎‍♂️	man kneeling	person activity	people
🧎‍♀️	woman kneeling	person activity	people
🧎‍➡️	person kneeling facing right	person activity	people
🧎‍♀️‍➡️	woman kneeling facing right	person activity	people
🧎‍♂️‍➡️	man kneeling facing right	person activity	people
🧑‍🦯	person with white cane	person activity	people
🧑‍🦯‍➡️	person with white cane facing right	person activity	people
👨‍🦯	man with white cane	person activity	people
👨‍🦯‍➡️	man with white cane facing right	person activity	people
👩‍🦯	woman with white cane	person activity	people
👩‍🦯‍➡️	woman with white cane facing right	person activity	people
🧑‍🦼	person in motorized wheelchair	person activity	people
🧑‍🦼‍➡️	person in motorized wheelchair facing right	person activity	people
👨‍🦼	man in motorized wheelchair	person activity	people
👨‍🦼‍➡️	man in motorized wheelchair facing right	person activity	people
👩‍🦼	woman in motorized wheelchair	person activity	people
👩‍🦼‍➡️	woman in motorized wheelchair facing right	person activity	people
🧑‍🦽	person in manual wheelchair	person activity	people
🧑‍🦽‍➡️	person in manual wheelchair facing right	person activity	people
👨‍🦽	man in manual wheelchair	person activity	people
👨‍🦽‍➡️	man in manual wheelchair facing right	person activity	people
👩‍🦽	woman in manual wheelchair	person activity	people
👩‍🦽‍➡️	woman in manual wheelchair facing right	person activity	people
🏃	person running	person activity	people
🏃‍♂️	man running	person activity	people
🏃‍♀️	woman running	person activity	people
🏃‍➡️	person running facing right	person activity	people
🏃‍♀️‍➡️	woman running facing right	person activity	people
🏃‍♂️‍➡️	man running facing right	person activity	people
💃	woman dancing	person activity	people
🕺	man dancing	person activity	people
🕴️	person in suit levitating	person activity	people
👯	people with bunny ears	person activity	people
👯‍♂️	men with bunny ears	person activity	people
👯‍♀️	women with bunny ears	person activity	people
🧖	person in steamy room	person activity	people
🧖‍♂️	man in steamy room	person activity	people
🧖‍♀️	woman in steamy room	person activity	people
🧗	person climbing	person activity	people
🧗‍♂️	man climbing	person activity	people
🧗‍♀️	woman climbing	person activity	people
🤺	person fencing	person sport	people
🏇	horse racing	person sport	people
⛷️	skier	person sport	people
🏂	snowboarder	person sport	people
🏌️	person golfing	person sport	people
🏌️‍♂️	man golfing	person sport	people
🏌️‍♀️	woman golfing	person sport	people
🏄	person surfing	person sport	people
🏄‍♂️	man surfing	person sport	people
🏄‍♀️	woman surfing	person sport	people
🚣	person rowing boat	person sport	people
🚣‍♂️	man rowing boat	person sport	people
🚣‍♀️	woman rowing boat	person sport	people
🏊	person swimming	person sport	people
🏊‍♂️	man swimming	person sport	people
🏊‍♀️	woman swimming	person sport	people
⛹️	person bouncing ball	person sport	people
⛹️‍♂️	man bouncing ball	person sport	people
⛹️‍♀️	woman bouncing ball	person sport	people
🏋️	person lifting weights	person sport	people
🏋️‍♂️	man lifting weights	person sport	people
🏋️‍♀️	woman lifting weights	person sport	people
🚴	person biking	person sport	people
🚴‍♂️	man biking	person sport	people
🚴‍♀️	woman biking	person sport	people
🚵	person mountain biking	person sport	people
🚵‍♂️	man mountain biking	person sport	people
🚵‍♀️	woman mountain biking	person sport	people
🤸	person cartwheeling	person sport	people
🤸‍♂️	man cartwheeling	person sport	people
🤸‍♀️	woman cartwheeling	person sport	people
🤼	people wrestling	person sport	people
🤼‍♂️	men wrestling	person sport	people
🤼‍♀️	women wrestling	person sport	people
🤽	person playing water polo	person sport	people
🤽‍♂️	man playing water polo	person sport	people
🤽‍♀️	woman playing water polo	person sport	people
🤾	person playing handball	person sport	people
🤾‍♂️	man playing handball	person sport	people
🤾‍♀️	woman playing handball	person sport	people
🤹	person juggling	person sport	people
🤹‍♂️	man juggling	person sport	people
🤹‍♀️	woman juggling	person sport	people
🧘	person in lotus position	person resting	people
🧘‍♂️	man in lotus position	person resting	people
🧘‍♀️	woman in lotus position	person resting	people
🛀	person taking bath	person resting	people
🛌	person in bed	person resting	people
🧑‍🤝‍🧑	people holding hands	family	people
👭	women holding hands	family	people
👫	woman and man holding hands	family	people
👬	men holding hands	family	people
💏	kiss	family	people
👩‍❤️‍💋‍👨	kiss: woman, man	family	people
👨‍❤️‍💋‍👨	kiss: man, man	family	people
👩‍❤️‍💋‍👩	kiss: woman, woman	family	people
💑	couple with heart	family	people
👩‍❤️‍👨	couple with heart: woman, man	family	people
👨‍❤️‍👨	couple with heart: man, man	family	people
👩‍❤️‍👩	couple with heart: woman, woman	family	people
👨‍👩‍👦	family: man, woman, boy	family	people
👨‍👩‍👧	family: man, woman, girl	family	people
👨‍👩‍👧‍👦	family: man, woman, girl, boy	family	people
👨‍👩‍👦‍👦	family: man, woman, boy, boy	family	people
👨‍👩‍👧‍👧	family: man, woman, girl, girl	family	people
👨‍👨‍👦	family: man, man, boy	family	people
👨‍👨‍👧	family: man, man, girl	family	people
👨‍👨‍👧‍👦	family: man, man, girl, boy	family	people
👨‍👨‍👦‍👦	family: man, man, boy, boy	family	people
👨‍👨‍👧‍👧	family: man, man, girl, girl	family	people
👩‍👩‍👦	family: woman, woman, boy	family	people
👩‍👩‍👧	family: woman, woman, girl	family	people
👩‍👩‍👧‍👦	family: woman, woman, girl, boy	family	people
👩‍👩‍👦‍👦	family: woman, woman, boy, boy	family	people
👩‍👩‍👧‍👧	family: woman, woman, girl, girl	family	people
👨‍👦	family: man, boy	family	people
👨‍👦‍👦	family: man, boy, boy	family	people
👨‍👧	family: man, girl	family	people
👨‍👧‍👦	family: man, girl, boy	family	people
👨‍👧‍👧	family: man, girl, girl	family	people
👩‍👦	family: woman, boy	family	people
👩‍👦‍👦	family: woman, boy, boy	family	people
👩‍👧	family: woman, girl	family	people
👩‍👧‍👦	family: woman, girl, boy	family	people
👩‍👧‍👧	family: woman, girl, girl	family	people
🗣️	speaking head	person symbol	people
👤	bust in silhouette	person symbol	people
👥	busts in silhouette	person symbol	people
🫂	people hugging	person symbol	people
👪	family	person symbol	people
🧑‍🧑‍🧒	family: adult, adult, child	person symbol	people
🧑‍🧑‍🧒‍🧒	family: adult, adult, child, child	person symbol	people
🧑‍🧒	family: adult, child	person symbol	people
🧑‍🧒‍🧒	family: adult, child, child	person symbol	people
👣	footprints	person symbol	people
🫆	fingerprint	person symbol	people
🐵	monkey face	animal mammal	animals
🐒	monkey	animal mammal	animals
🦍	gorilla	animal mammal	animals
🦧	orangutan	animal mammal	animals
🐶	dog face	animal mammal	animals
🐕	dog	animal mammal	animals
🦮	guide dog	animal mammal	animals
🐕‍🦺	service dog	animal mammal	animals
🐩	poodle	animal mammal	animals
🐺	wolf	animal mammal	animals
🦊	fox	animal mammal	animals
🦝	raccoon	animal mammal	animals
🐱	cat face	animal mammal	animals
🐈	cat	animal mammal	animals
🐈‍⬛	black cat	animal mammal	animals
🦁	lion	animal mammal	animals
🐯	tiger face	animal mammal	animals
🐅	tiger	animal mammal	animals
🐆	leopard	animal mammal	animals
🐴	horse face	animal mammal	animals
🫎	moose	animal mammal	animals
🫏	donkey	animal mammal	animals
🐎	horse	animal mammal	animals
🦄	unicorn	animal mammal	animals
🦓	zebra	animal mammal	animals
🦌	deer	animal mammal	animals
🦬	bison	animal mammal	animals
🐮	cow face	animal mammal	animals
🐂	ox	animal mammal	animals
🐃	water buffalo	animal mammal	animals
🐄	cow	animal mammal	animals
🐷	pig face	animal mammal	animals
🐖	pig	animal mammal	animals
🐗	boar	animal mammal	animals
🐽	pig nose	animal mammal	animals
🐏	ram	animal mammal	animals
🐑	ewe	animal mammal	animals
🐐	goat	animal mammal	animals
🐪	camel	animal mammal	animals
🐫	two-hump camel	animal mammal	animals
🦙	llama	animal mammal	animals
🦒	giraffe	animal mammal	animals
🐘	elephant	animal mammal	animals
🦣	mammoth	animal mammal	animals
🦏	rhinoceros	animal mammal	animals
🦛	hippopotamus	animal mammal	animals
🐭	mouse face	animal mammal	animals
🐁	mouse	animal mammal	animals
🐀	rat	animal mammal	animals
🐹	hamster	animal mammal	animals
🐰	rabbit face	animal mammal	animals
🐇	rabbit	animal mammal	animals
🐿️	chipmunk	animal mammal	animals
🦫	beaver	animal mammal	animals
🦔	hedgehog	animal mammal	animals
🦇	bat	animal mammal	animals
🐻	bear	animal mammal	animals
🐻‍❄️	polar bear	animal mammal	animals
🐨	koala	animal mammal	animals
🐼	panda	animal mammal	animals
🦥	sloth	animal mammal	animals
🦦	otter	animal mammal	animals
🦨	skunk	animal mammal	animals
🦘	kangaroo	animal mammal	animals
🦡	badger	animal mammal	animals
🐾	paw prints	animal mammal	animals
🦃	turkey	animal bird	animals
🐔	chicken	animal bird	animals
🐓	rooster	animal bird	animals
🐣	hatching chick	animal bird	animals
🐤	baby chick	animal bird	animals
🐥	front-facing baby chick	animal bird	animals
🐦	bird	animal bird	animals
🐧	penguin	animal bird	animals
🕊️	dove	animal bird	animals
🦅	eagle	animal bird	animals
🦆	duck	animal bird	animals
🦢	swan	animal bird	animals
🦉	owl	animal bird	animals
🦤	dodo	animal bird	animals
🪶	feather	animal bird	animals
🦩	flamingo	animal bird	animals
🦚	peacock	animal bird	animals
🦜	parrot	animal bird	animals
🪽	wing	animal bird	animals
🐦‍⬛	black bird	animal bird	animals
🪿	goose	animal bird	animals
🐦‍🔥	phoenix	animal bird	animals
🐸	frog	animal amphibian	animals
🐊	crocodile	animal reptile	animals
🐢	turtle	animal reptile	animals
🦎	lizard	animal reptile	animals
🐍	snake	animal reptile	animals
🐲	dragon face	animal reptile	animals
🐉	dragon	animal reptile	animals
🦕	sauropod	animal reptile	animals
🦖	T-Rex	animal reptile	animals
🐳	spouting whale	animal marine	animals
🐋	whale	animal marine	animals
🐬	dolphin	animal marine	animals
🦭	seal	animal marine	animals
🐟	fish	animal marine	animals
🐠	tropical fish	animal marine	animals
🐡	blowfish	animal marine	animals
🦈	shark	animal marine	animals
🐙	octopus	animal marine	animals
🐚	spiral shell	animal marine	animals
🪸	coral	animal marine	animals
🪼	jellyfish	animal marine	animals
🦀	crab	animal marine	animals
🦞	lobster	animal marine	animals
🦐	shrimp	animal marine	animals
🦑	squid	animal marine	animals
🦪	oyster	animal marine	animals
🐌	snail	animal bug	animals
🦋	butterfly	animal bug	animals
🐛	bug	animal bug	animals
🐜	ant	animal bug	animals
🐝	honeybee	animal bug	animals
🪲	beetle	animal bug	animals
🐞	lady beetle	animal bug	animals
🦗	cricket	animal bug	animals
🪳	cockroach	animal bug	animals
🕷️	spider	animal bug	animals
🕸️	spider web	animal bug	animals
🦂	scorpion	animal bug	animals
🦟	mosquito	animal bug	animals
🪰	fly	animal bug	animals
🪱	worm	animal bug	animals
🦠	microbe	animal bug	animals
💐	bouquet	plant flower	animals
🌸	cherry blossom	plant flower	animals
💮	white flower	plant flower	animals
🪷	lotus	plant flower	animals
🏵️	rosette	plant flower	animals
🌹	rose	plant flower	animals
🥀	wilted flower	plant flower	animals
🌺	hibiscus	plant flower	animals
🌻	sunflower	plant flower	animals
🌼	blossom	plant flower	animals
🌷	tulip	plant flower	animals
🪻	hyacinth	plant flower	animals
🌱	seedling	plant other	animals
🪴	potted plant	plant other	animals
🌲	evergreen tree	plant other	animals
🌳	deciduous tree	plant other	animals
🌴	palm tree	plant other	animals
🌵	cactus	plant other	animals
🌾	sheaf of rice	plant other	animals
🌿	herb	plant other	animals
☘️	shamrock	plant other	animals
🍀	four leaf clover	plant other	animals
🍁	maple leaf	plant other	animals
🍂	fallen leaf	plant other	animals
🍃	leaf fluttering in wind	plant other	animals
🪹	empty nest	plant other	animals
🪺	nest with eggs	plant other	animals
🍄	mushroom	plant other	animals
🪾	leafless tree	plant other	animals
🍇	grapes	food fruit	food
🍈	melon	food fruit	food
🍉	watermelon	food fruit	food
🍊	tangerine	food fruit	food
🍋	lemon	food fruit	food
🍋‍🟩	lime	food fruit	food
🍌	banana	food fruit	food
🍍	pineapple	food fruit	food
🥭	mango	food fruit	food
🍎	red apple	food fruit	food
🍏	green apple	food fruit	food
🍐	pear	food fruit	food
🍑	peach	food fruit	food
🍒	cherries	food fruit	food
🍓	strawberry	food fruit	food
🫐	blueberries	food fruit	food
🥝	kiwi fruit	food fruit	food
🍅	tomato	food fruit	food
🫒	olive	food fruit	food
🥥	coconut	food fruit	food
🥑	avocado	food vegetable	food
🍆	eggplant	food vegetable	food
🥔	potato	food vegetable	food
🥕	carrot	food vegetable	food
🌽	ear of corn	food vegetable	food
🌶️	hot pepper	food vegetable	food
🫑	bell pepper	food vegetable	food
🥒	cucumber	food vegetable	food
🥬	leafy green	food vegetable	food
🥦	broccoli	food vegetable	food
🧄	garlic	food vegetable	food
🧅	onion	food vegetable	food
🥜	peanuts	food vegetable	food
🫘	beans	food vegetable	food
🌰	chestnut	food vegetable	food
🫚	ginger root	food vegetable	food
🫛	pea pod	food vegetable	food
🍄‍🟫	brown mushroom	food vegetable	food
🫜	root vegetable	food vegetable	food
🍞	bread	food prepared	food
🥐	croissant	food prepared	food
🥖	baguette bread	food prepared	food
🫓	flatbread	food prepared	food
🥨	pretzel	food prepared	food
🥯	bagel	food prepared	food
🥞	pancakes	food prepared	food
🧇	waffle	food prepared	food
🧀	cheese wedge	food prepared	food
🍖	meat on bone	food prepared	food
🍗	poultry leg	food prepared	food
🥩	cut of meat	food prepared	food
🥓	bacon	food prepared	food
🍔	hamburger	food prepared	food
🍟	french fries	food prepared	food
🍕	pizza	food prepared	food
🌭	hot dog	food prepared	food
🥪	sandwich	food prepared	food
🌮	taco	food prepared	food
🌯	burrito	food prepared	food
🫔	tamale	food prepared	food
🥙	stuffed flatbread	food prepared	food
🧆	falafel	food prepared	food
🥚	egg	food prepared	food
🍳	cooking	food prepared	food
🥘	shallow pan of food	food prepared	food
🍲	pot of food	food prepared	food
🫕	fondue	food prepared	food
🥣	bowl with spoon	food prepared	food
🥗	green salad	food prepared	food
🍿	popcorn	food prepared	food
🧈	butter	food prepared	food
🧂	salt	food prepared	food
🥫	canned food	food prepared	food
🍱	bento box	food asian	food
🍘	rice cracker	food asian	food
🍙	rice ball	food asian	food
🍚	cooked rice	food asian	food
🍛	curry rice	food asian	food
🍜	steaming bowl	food asian	food
🍝	spaghetti	food asian	food
🍠	roasted sweet potato	food asian	food
🍢	oden	food asian	food
🍣	sushi	food asian	food
🍤	fried shrimp	food asian	food
🍥	fish cake with swirl	food asian	food
🥮	moon cake	food asian	food
🍡	dango	food asian	food
🥟	dumpling	food asian	food
🥠	fortune cookie	food asian	food
🥡	takeout box	food asian	food
🍦	soft ice cream	food sweet	food
🍧	shaved ice	food sweet	food
🍨	ice cream	food sweet	food
🍩	doughnut	food sweet	food
🍪	cookie	food sweet	food
🎂	birthday cake	food sweet	food
🍰	shortcake	food sweet	food
🧁	cupcake	food sweet	food
🥧	pie	food sweet	food
🍫	chocolate bar	food sweet	food
🍬	candy	food sweet	food
🍭	lollipop	food sweet	food
🍮	custard	food sweet	food
🍯	honey pot	food sweet	food
🍼	baby bottle	drink	food
🥛	glass of milk	drink	food
☕	hot beverage	drink	food
🫖	teapot	drink	food
🍵	teacup without handle	drink	food
🍶	sake	drink	food
🍾	bottle with popping cork	drink	food
🍷	wine glass	drink	food
🍸	cocktail glass	drink	food
🍹	tropical drink	drink	food
🍺	beer mug	drink	food
🍻	clinking beer mugs	drink	food
🥂	clinking glasses	drink	food
🥃	tumbler glass	drink	food
🫗	pouring liquid	drink	food
🥤	cup with straw	drink	food
🧋	bubble tea	drink	food
🧃	beverage box	drink	food
🧉	mate	drink	food
🧊	ice	drink	food
🥢	chopsticks	dishware	food
🍽️	fork and knife with plate	dishware	food
🍴	fork and knife	dishware	food
🥄	spoon	dishware	food
🔪	kitchen knife	dishware	food
🫙	jar	dishware	food
🏺	amphora	dishware	food
🌍	globe showing Europe-Africa	place map	travel
🌎	globe showing Americas	place map	travel
🌏	globe showing Asia-Australia	place map	travel
🌐	globe with meridians	place map	travel
🗺️	world map	place map	travel
🗾	map of Japan	place map	travel
🧭	compass	place map	travel
🏔️	snow-capped mountain	place geographic	travel
⛰️	mountain	place geographic	travel
🌋	volcano	place geographic	travel
🗻	mount fuji	place geographic	travel
🏕️	camping	place geographic	travel
🏖️	beach with umbrella	place geographic	travel
🏜️	desert	place geographic	travel
🏝️	desert island	place geographic	travel
🏞️	national park	place geographic	travel
🏟️	stadium	place building	travel
🏛️	classical building	place building	travel
🏗️	building construction	place building	travel
🧱	brick	place building	travel
🪨	rock	place building	travel
🪵	wood	place building	travel
🛖	hut	place building	travel
🏘️	houses	place building	travel
🏚️	derelict house	place building	travel
🏠	house	place building	travel
🏡	house with garden	place building	travel
🏢	office building	place building	travel
🏣	Japanese post office	place building	travel
🏤	post office	place building	travel
🏥	hospital	place building	travel
🏦	bank	place building	travel
🏨	hotel	place building	travel
🏩	love hotel	place building	travel
🏪	convenience store	place building	travel
🏫	school	place building	travel
🏬	department store	place building	travel
🏭	factory	place building	travel
🏯	Japanese castle	place building	travel
🏰	castle	place building	travel
💒	wedding	place building	travel
🗼	Tokyo tower	place building	travel
🗽	Statue of Liberty	place building	travel
⛪	church	place religious	travel
🕌	mosque	place religious	travel
🛕	hindu temple	place religious	travel
🕍	synagogue	place religious	travel
⛩️	shinto shrine	place religious	travel
🕋	kaaba	place religious	travel
⛲	fountain	place other	travel
⛺	tent	place other	travel
🌁	foggy	place other	travel
🌃	night with stars	place other	travel
🏙️	cityscape	place other	travel
🌄	sunrise over mountains	place other	travel
🌅	sunrise	place other	travel
🌆	cityscape at dusk	place other	travel
🌇	sunset	place other	travel
🌉	bridge at night	place other	travel
♨️	hot springs	place other	travel
🎠	carousel horse	place other	travel
🛝	playground slide	place other	travel
🎡	ferris wheel	place other	travel
🎢	roller coaster	place other	travel
💈	barber pole	place other	travel
🎪	circus tent	place other	travel
🚂	locomotive	transport ground	travel
🚃	railway car	transport ground	travel
🚄	high-speed train	transport ground	travel
🚅	bullet train	transport ground	travel
🚆	train	transport ground	travel
🚇	metro	transport ground	travel
🚈	light rail	transport ground	travel
🚉	station	transport ground	travel
🚊	tram	transport ground	travel
🚝	monorail	transport ground	travel
🚞	mountain railway	transport ground	travel
🚋	tram car	transport ground	travel
🚌	bus	transport ground	travel
🚍	oncoming bus	transport ground	travel
🚎	trolleybus	transport ground	travel
🚐	minibus	transport ground	travel
🚑	ambulance	transport ground	travel
🚒	fire engine	transport ground	travel
🚓	police car	transport ground	travel
🚔	oncoming police car	transport ground	travel
🚕	taxi	transport ground	travel
🚖	oncoming taxi	transport ground	travel
🚗	automobile	transport ground	travel
🚘	oncoming automobile	transport ground	travel
🚙	sport utility vehicle	transport ground	travel
🛻	pickup truck	transport ground	travel
🚚	delivery truck	transport ground	travel
🚛	articulated lorry	transport ground	travel
🚜	tractor	transport ground	travel
🏎️	racing car	transport ground	travel
🏍️	motorcycle	transport ground	travel
🛵	motor scooter	transport ground	travel
🦽	manual wheelchair	transport ground	travel
🦼	motorized wheelchair	transport ground	travel
🛺	auto rickshaw	transport ground	travel
🚲	bicycle	transport ground	travel
🛴	kick scooter	transport ground	travel
🛹	skateboard	transport ground	travel
🛼	roller skate	transport ground	travel
🚏	bus stop	transport ground	travel
🛣️	motorway	transport ground	travel
🛤️	railway track	transport ground	travel
🛢️	oil drum	transport ground	travel
⛽	fuel pump	transport ground	travel
🛞	wheel	transport ground	travel
🚨	police car light	transport ground	travel
🚥	horizontal traffic light	transport ground	travel
🚦	vertical traffic light	transport ground	travel
🛑	stop sign	transport ground	travel
🚧	construction	transport ground	travel
⚓	anchor	transport water	travel
🛟	ring buoy	transport water	travel
⛵	sailboat	transport water	travel
🛶	canoe	transport water	travel
🚤	speedboat	transport water	travel
🛳️	passenger ship	transport water	travel
⛴️	ferry	transport water	travel
🛥️	motor boat	transport water	travel
🚢	ship	transport water	travel
✈️	airplane	transport air	travel
🛩️	small airplane	transport air	travel
🛫	airplane departure	transport air	travel
🛬	airplane arrival	transport air	travel
🪂	parachute	transport air	travel
💺	seat	transport air	travel
🚁	helicopter	transport air	travel
🚟	suspension railway	transport air	travel
🚠	mountain cableway	transport air	travel
🚡	aerial tramway	transport air	travel
🛰️	satellite	transport air	travel
🚀	rocket	transport air	travel
🛸	flying saucer	transport air	travel
🛎️	bellhop bell	hotel	travel
🧳	luggage	hotel	travel
⌛	hourglass done	time	travel
⏳	hourglass not done	time	travel
⌚	watch	time	travel
⏰	alarm clock	time	travel
⏱️	stopwatch	time	travel
⏲️	timer clock	time	travel
🕰️	mantelpiece clock	time	travel
🕛	twelve o’clock	time	travel
🕧	twelve-thirty	time	travel
🕐	one o’clock	time	travel
🕜	one-thirty	time	travel
🕑	two o’clock	time	travel
🕝	two-thirty	time	travel
🕒	three o’clock	time	travel
🕞	three-thirty	time	travel
🕓	four o’clock	time	travel
🕟	four-thirty	time	travel
🕔	five o’clock	time	travel
🕠	five-thirty	time	travel
🕕	six o’clock	time	travel
🕡	six-thirty	time	travel
🕖	seven o’clock	time	travel
🕢	seven-thirty	time	travel
🕗	eight o’clock	time	travel
🕣	eight-thirty	time	travel
🕘	nine o’clock	time	travel
🕤	nine-thirty	time	travel
🕙	ten o’clock	time	travel
🕥	ten-thirty	time	travel
🕚	eleven o’clock	time	travel
🕦	eleven-thirty	time	travel
🌑	new moon	sky & weather	travel
🌒	waxing crescent moon	sky & weather	travel
🌓	first quarter moon	sky & weather	travel
🌔	waxing gibbous moon	sky & weather	travel
🌕	full moon	sky & weather	travel
🌖	waning gibbous moon	sky & weather	travel
🌗	last quarter moon	sky & weather	travel
🌘	waning crescent moon	sky & weather	travel
🌙	crescent moon	sky & weather	travel
🌚	new moon face	sky & weather	travel
🌛	first quarter moon face	sky & weather	travel
🌜	last quarter moon face	sky & weather	travel
🌡️	thermometer	sky & weather	travel
☀️	sun	sky & weather	travel
🌝	full moon face	sky & weather	travel
🌞	sun with face	sky & weather	travel
🪐	ringed planet	sky & weather	travel
⭐	star	sky & weather	travel
🌟	glowing star	sky & weather	travel
🌠	shooting star	sky & weather	travel
🌌	milky way	sky & weather	travel
☁️	cloud	sky & weather	travel
⛅	sun behind cloud	sky & weather	travel
⛈️	cloud with lightning and rain	sky & weather	travel
🌤️	sun behind small cloud	sky & weather	travel
🌥️	sun behind large cloud	sky & weather	travel
🌦️	sun behind rain cloud	sky & weather	travel
🌧️	cloud with rain	sky & weather	travel
🌨️	cloud with snow	sky & weather	travel
🌩️	cloud with lightning	sky & weather	travel
🌪️	tornado	sky & weather	travel
🌫️	fog	sky & weather	travel
🌬️	wind face	sky & weather	travel
🌀	cyclone	sky & weather	travel
🌈	rainbow	sky & weather	travel
🌂	closed umbrella	sky & weather	travel
☂️	umbrella	sky & weather	travel
☔	umbrella with rain drops	sky & weather	travel
⛱️	umbrella on ground	sky & weather	travel
⚡	high voltage	sky & weather	travel
❄️	snowflake	sky & weather	travel
☃️	snowman	sky & weather	travel
⛄	snowman without snow	sky & weather	travel
☄️	comet	sky & weather	travel
🔥	fire	sky & weather	travel
💧	droplet	sky & weather	travel
🌊	water wave	sky & weather	travel
🎃	jack-o-lantern	event	activities
🎄	Christmas tree	event	activities
🎆	fireworks	event	activities
🎇	sparkler	event	activities
🧨	firecracker	event	activities
✨	sparkles	event	activities
🎈	balloon	event	activities
🎉	party popper	event	activities
🎊	confetti ball	event	activities
🎋	tanabata tree	event	activities
🎍	pine decoration	event	activities
🎎	Japanese dolls	event	activities
🎏	carp streamer	event	activities
🎐	wind chime	event	activities
🎑	moon viewing ceremony	event	activities
🧧	red envelope	event	activities
🎀	ribbon	event	activities
🎁	wrapped gift	event	activities
🎗️	reminder ribbon	event	activities
🎟️	admission tickets	event	activities
🎫	ticket	event	activities
🎖️	military medal	award medal	activities
🏆	trophy	award medal	activities
🏅	sports medal	award medal	activities
🥇	1st place medal	award medal	activities
🥈	2nd place medal	award medal	activities
🥉	3rd place medal	award medal	activities
⚽	soccer ball	sport	activities
⚾	baseball	sport	activities
🥎	softball	sport	activities
🏀	basketball	sport	activities
🏐	volleyball	sport	activities
🏈	american football	sport	activities
🏉	rugby football	sport	activities
🎾	tennis	sport	activities
🥏	flying disc	sport	activities
🎳	bowling	sport	activities
🏏	cricket game	sport	activities
🏑	field hockey	sport	activities
🏒	ice hockey	sport	activities
🥍	lacrosse	sport	activities
🏓	ping pong	sport	activities
🏸	badminton	sport	activities
🥊	boxing glove	sport	activities
🥋	martial arts uniform	sport	activities
🥅	goal net	sport	activities
⛳	flag in hole	sport	activities
⛸️	ice skate	sport	activities
🎣	fishing pole	sport	activities
🤿	diving mask	sport	activities
🎽	running shirt	sport	activities
🎿	skis	sport	activities
🛷	sled	sport	activities
🥌	curling stone	sport	activities
🎯	bullseye	game	activities
🪀	yo-yo	game	activities
🪁	kite	game	activities
🔫	water pistol	game	activities
🎱	pool 8 ball	game	activities
🔮	crystal ball	game	activities
🪄	magic wand	game	activities
🎮	video game	game	activities
🕹️	joystick	game	activities
🎰	slot machine	game	activities
🎲	game die	game	activities
🧩	puzzle piece	game	activities
🧸	teddy bear	game	activities
🪅	piñata	game	activities
🪩	mirror ball	game	activities
🪆	nesting dolls	game	activities
♠️	spade suit	game	activities
♥️	heart suit	game	activities
♦️	diamond suit	game	activities
♣️	club suit	game	activities
♟️	chess pawn	game	activities
🃏	joker	game	activities
🀄	mahjong red dragon	game	activities
🎴	flower playing cards	game	activities
🎭	performing arts	arts & crafts	activities
🖼️	framed picture	arts & crafts	activities
🎨	artist palette	arts & crafts	activities
🧵	thread	arts & crafts	activities
🪡	sewing needle	arts & crafts	activities
🧶	yarn	arts & crafts	activities
🪢	knot	arts & crafts	activities
👓	glasses	clothing	objects
🕶️	sunglasses	clothing	objects
🥽	goggles	clothing	objects
🥼	lab coat	clothing	objects
🦺	safety vest	clothing	objects
👔	necktie	clothing	objects
👕	t-shirt	clothing	objects
👖	jeans	clothing	objects
🧣	scarf	clothing	objects
🧤	gloves	clothing	objects
🧥	coat	clothing	objects
🧦	socks	clothing	objects
👗	dress	clothing	objects
👘	kimono	clothing	objects
🥻	sari	clothing	objects
🩱	one-piece swimsuit	clothing	objects
🩲	briefs	clothing	objects
🩳	shorts	clothing	objects
👙	bikini	clothing	objects
👚	woman’s clothes	clothing	objects
🪭	folding hand fan	clothing	objects
👛	purse	clothing	objects
👜	handbag	clothing	objects
👝	clutch bag	clothing	objects
🛍️	shopping bags	clothing	objects
🎒	backpack	clothing	objects
🩴	thong sandal	clothing	objects
👞	man’s shoe	clothing	objects
👟	running shoe	clothing	objects
🥾	hiking boot	clothing	objects
🥿	flat shoe	clothing	objects
👠	high-heeled shoe	clothing	objects
👡	woman’s sandal	clothing	objects
🩰	ballet shoes	clothing	objects
👢	woman’s boot	clothing	objects
🪮	hair pick	clothing	objects
👑	crown	clothing	objects
👒	woman’s hat	clothing	objects
🎩	top hat	clothing	objects
🎓	graduation cap	clothing	objects
🧢	billed cap	clothing	objects
🪖	military helmet	clothing	objects
⛑️	rescue worker’s helmet	clothing	objects
📿	prayer beads	clothing	objects
💄	lipstick	clothing	objects
💍	ring	clothing	objects
💎	gem stone	clothing	objects
🔇	muted speaker	sound	objects
🔈	speaker low volume	sound	objects
🔉	speaker medium volume	sound	objects
🔊	speaker high volume	sound	objects
📢	loudspeaker	sound	objects
📣	megaphone	sound	objects
📯	postal horn	sound	objects
🔔	bell	sound	objects
🔕	bell with slash	sound	objects
🎼	musical score	music	objects
🎵	musical note	music	objects
🎶	musical notes	music	objects
🎙️	studio microphone	music	objects
🎚️	level slider	music	objects
🎛️	control knobs	music	objects
🎤	microphone	music	objects
🎧	headphone	music	objects
📻	radio	music	objects
🎷	saxophone	musical instrument	objects
🎺	trumpet	musical instrument	objects
🪗	accordion	musical instrument	objects
🎸	guitar	musical instrument	objects
🎹	musical keyboard	musical instrument	objects
🎻	violin	musical instrument	objects
🪕	banjo	musical instrument	objects
🥁	drum	musical instrument	objects
🪘	long drum	musical instrument	objects
🪇	maracas	musical instrument	objects
🪈	flute	musical instrument	objects
🪉	harp	musical instrument	objects
📱	mobile phone	phone	objects
📲	mobile phone with arrow	phone	objects
☎️	telephone	phone	objects
📞	telephone receiver	phone	objects
📟	pager	phone	objects
📠	fax machine	phone	objects
🔋	battery	computer	objects
🪫	low battery	computer	objects
🔌	electric plug	computer	objects
💻	laptop	computer	objects
🖥️	desktop computer	computer	objects
🖨️	printer	computer	objects
⌨️	keyboard	computer	objects
🖱️	computer mouse	computer	objects
🖲️	trackball	computer	objects
💽	computer disk	computer	objects
💾	floppy disk	computer	objects
💿	optical disk	computer	objects
📀	dvd	computer	objects
🧮	abacus	computer	objects
🎥	movie camera	light & video	objects
🎞️	film frames	light & video	objects
📽️	film projector	light & video	objects
🎬	clapper board	light & video	objects
📺	television	light & video	objects
📷	camera	light & video	objects
📸	camera with flash	light & video	objects
📹	video camera	light & video	objects
📼	videocassette	light & video	objects
🔍	magnifying glass tilted left	light & video	objects
🔎	magnifying glass tilted right	light & video	objects
🕯️	candle	light & video	objects
💡	light bulb	light & video	objects
🔦	flashlight	light & video	objects
🏮	red paper lantern	light & video	objects
🪔	diya lamp	light & video	objects
📔	notebook with decorative cover	book paper	objects
📕	closed book	book paper	objects
📖	open book	book paper	objects
📗	green book	book paper	objects
📘	blue book	book paper	objects
📙	orange book	book paper	objects
📚	books	book paper	objects
📓	notebook	book paper	objects
📒	ledger	book paper	objects
📃	page with curl	book paper	objects
📜	scroll	book paper	objects
📄	page facing up	book paper	objects
📰	newspaper	book paper	objects
🗞️	rolled-up newspaper	book paper	objects
📑	bookmark tabs	book paper	objects
🔖	bookmark	book paper	objects
🏷️	label	book paper	objects
🪙	coin	money	objects
💰	money bag	money	objects
💴	yen banknote	money	objects
💵	dollar banknote	money	objects
💶	euro banknote	money	objects
💷	pound banknote	money	objects
💸	money with wings	money	objects
💳	credit card	money	objects
🧾	receipt	money	objects
💹	chart increasing with yen	money	objects
✉️	envelope	mail	objects
📧	e-mail	mail	objects
📨	incoming envelope	mail	objects
📩	envelope with arrow	mail	objects
📤	outbox tray	mail	objects
📥	inbox tray	mail	objects
📦	package	mail	objects
📫	closed mailbox with raised flag	mail	objects
📪	closed mailbox with lowered flag	mail	objects
📬	open mailbox with raised flag	mail	objects
📭	open mailbox with lowered flag	mail	objects
📮	postbox	mail	objects
🗳️	ballot box with ballot	mail	objects
✏️	pencil	writing	objects
✒️	black nib	writing	objects
🖋️	fountain pen	writing	objects
🖊️	pen	writing	objects
🖌️	paintbrush	writing	objects
🖍️	crayon	writing	objects
📝	memo	writing	objects
💼	briefcase	office	objects
📁	file folder	office	objects
📂	open file folder	office	objects
🗂️	card index dividers	office	objects
📅	calendar	office	objects
📆	tear-off calendar	office	objects
🗒️	spiral notepad	office	objects
🗓️	spiral calendar	office	objects
📇	card index	office	objects
📈	chart increasing	office	objects
📉	chart decreasing	office	objects
📊	bar chart	office	objects
📋	clipboard	office	objects
📌	pushpin	office	objects
📍	round pushpin	office	objects
📎	paperclip	office	objects
🖇️	linked paperclips	office	objects
📏	straight ruler	office	objects
📐	triangular ruler	office	objects
✂️	scissors	office	objects
🗃️	card file box	office	objects
🗄️	file cabinet	office	objects
🗑️	wastebasket	office	objects
🔒	locked	lock	objects
🔓	unlocked	lock	objects
🔏	locked with pen	lock	objects
🔐	locked with key	lock	objects
🔑	key	lock	objects
🗝️	old key	lock	objects
🔨	hammer	tool	objects
🪓	axe	tool	objects
⛏️	pick	tool	objects
⚒️	hammer and pick	tool	objects
🛠️	hammer and wrench	tool	objects
🗡️	dagger	tool	objects
⚔️	crossed swords	tool	objects
💣	bomb	tool	objects
🪃	boomerang	tool	objects
🏹	bow and arrow	tool	objects
🛡️	shield	tool	objects
🪚	carpentry saw	tool	objects
🔧	wrench	tool	objects
🪛	screwdriver	tool	objects
🔩	nut and bolt	tool	objects
⚙️	gear	tool	objects
🗜️	clamp	tool	objects
⚖️	balance scale	tool	objects
🦯	white cane	tool	objects
🔗	link	tool	objects
⛓️‍💥	broken chain	tool	objects
⛓️	chains	tool	objects
🪝	hook	tool	objects
🧰	toolbox	tool	objects
🧲	magnet	tool	objects
🪜	ladder	tool	objects
🪏	shovel	tool	objects
⚗️	alembic	science	objects
🧪	test tube	science	objects
🧫	petri dish	science	objects
🧬	dna	science	objects
🔬	microscope	science	objects
🔭	telescope	science	objects
📡	satellite antenna	science	objects
💉	syringe	medical	objects
🩸	drop of blood	medical	objects
💊	pill	medical	objects
🩹	adhesive bandage	medical	objects
🩼	crutch	medical	objects
🩺	stethoscope	medical	objects
🩻	x-ray	medical	objects
🚪	door	household	objects
🛗	elevator	household	objects
🪞	mirror	household	objects
🪟	window	household	objects
🛏️	bed	household	objects
🛋️	couch and lamp	household	objects
🪑	chair	household	objects
🚽	toilet	household	objects
🪠	plunger	household	objects
🚿	shower	household	objects
🛁	bathtub	household	objects
🪤	mouse trap	household	objects
🪒	razor	household	objects
🧴	lotion bottle	household	objects
🧷	safety pin	household	objects
🧹	broom	household	objects
🧺	basket	household	objects
🧻	roll of paper	household	objects
🪣	bucket	household	objects
🧼	soap	household	objects
🫧	bubbles	household	objects
🪥	toothbrush	household	objects
🧽	sponge	household	objects
🧯	fire extinguisher	household	objects
🛒	shopping cart	household	objects
🚬	cigarette	other object	objects
⚰️	coffin	other object	objects
🪦	headstone	other object	objects
⚱️	funeral urn	other object	objects
🧿	nazar amulet	other object	objects
🪬	hamsa	other object	objects
🗿	moai	other object	objects
🪧	placard	other object	objects
🪪	identification card	other object	objects
🏧	ATM sign	transport sign	symbols
🚮	litter in bin sign	transport sign	symbols
🚰	potable water	transport sign	symbols
♿	wheelchair symbol	transport sign	symbols
🚹	men’s room	transport sign	symbols
🚺	women’s room	transport sign	symbols
🚻	restroom	transport sign	symbols
🚼	baby symbol	transport sign	symbols
🚾	water closet	transport sign	symbols
🛂	passport control	transport sign	symbols
🛃	customs	transport sign	symbols
🛄	baggage claim	transport sign	symbols
🛅	left luggage	transport sign	symbols
⚠️	warning	warning	symbols
🚸	children crossing	warning	symbols
⛔	no entry	warning	symbols
🚫	prohibited	warning	symbols
🚳	no bicycles	warning	symbols
🚭	no smoking	warning	symbols
🚯	no littering	warning	symbols
🚱	non-potable water	warning	symbols
🚷	no pedestrians	warning	symbols
📵	no mobile phones	warning	symbols
🔞	no one under eighteen	warning	symbols
☢️	radioactive	warning	symbols
☣️	biohazard	warning	symbols
⬆️	up arrow	arrow	symbols
↗️	up-right arrow	arrow	symbols
➡️	right arrow	arrow	symbols
↘️	down-right arrow	arrow	symbols
⬇️	down arrow	arrow	symbols
↙️	down-left arrow	arrow	symbols
⬅️	left arrow	arrow	symbols
↖️	up-left arrow	arrow	symbols
↕️	up-down arrow	arrow	symbols
↔️	left-right arrow	arrow	symbols
↩️	right arrow curving left	arrow	symbols
↪️	left arrow curving right	arrow	symbols
⤴️	right arrow curving up	arrow	symbols
⤵️	right arrow curving down	arrow	symbols
🔃	clockwise vertical arrows	arrow	symbols
🔄	counterclockwise arrows button	arrow	symbols
🔙	BACK arrow	arrow	symbols
🔚	END arrow	arrow	symbols
🔛	ON! arrow	arrow	symbols
🔜	SOON arrow	arrow	symbols
🔝	TOP arrow	arrow	symbols
🛐	place of worship	religion	symbols
⚛️	atom symbol	religion	symbols
🕉️	om	religion	symbols
✡️	star of David	religion	symbols
☸️	wheel of dharma	religion	symbols
☯️	yin yang	religion	symbols
✝️	latin cross	religion	symbols
☦️	orthodox cross	religion	symbols
☪️	star and crescent	religion	symbols
☮️	peace symbol	religion	symbols
🕎	menorah	religion	symbols
🔯	dotted six-pointed star	religion	symbols
🪯	khanda	religion	symbols
♈	Aries	zodiac	symbols
♉	Taurus	zodiac	symbols
♊	Gemini	zodiac	symbols
♋	Cancer	zodiac	symbols
♌	Leo	zodiac	symbols
♍	Virgo	zodiac	symbols
♎	Libra	zodiac	symbols
♏	Scorpio	zodiac	symbols
♐	Sagittarius	zodiac	symbols
♑	Capricorn	zodiac	symbols
♒	Aquarius	zodiac	symbols
♓	Pisces	zodiac	symbols
⛎	Ophiuchus	zodiac	symbols
🔀	shuffle tracks button	av symbol	symbols
🔁	repeat button	av symbol	symbols
🔂	repeat single button	av symbol	symbols
▶️	play button	av symbol	symbols
⏩	fast-forward button	av symbol	symbols
⏭️	next track button	av symbol	symbols
⏯️	play or pause button	av symbol	symbols
◀️	reverse button	av symbol	symbols
⏪	fast reverse button	av symbol	symbols
⏮️	last track button	av symbol	symbols
🔼	upwards button	av symbol	symbols
⏫	fast up button	av symbol	symbols
🔽	downwards button	av symbol	symbols
⏬	fast down button	av symbol	symbols
⏸️	pause button	av symbol	symbols
⏹️	stop button	av symbol	symbols
⏺️	record button	av symbol	symbols
⏏️	eject button	av symbol	symbols
🎦	cinema	av symbol	symbols
🔅	dim button	av symbol	symbols
🔆	bright button	av symbol	symbols
📶	antenna bars	av symbol	symbols
🛜	wireless	av symbol	symbols
📳	vibration mode	av symbol	symbols
📴	mobile phone off	av symbol	symbols
♀️	female sign	gender	symbols
♂️	male sign	gender	symbols
⚧️	transgender symbol	gender	symbols
✖️	multiply	math	symbols
➕	plus	math	symbols
➖	minus	math	symbols
➗	divide	math	symbols
🟰	heavy equals sign	math	symbols
♾️	infinity	math	symbols
‼️	double exclamation mark	punctuation	symbols
⁉️	exclamation question mark	punctuation	symbols
❓	red question mark	punctuation	symbols
❔	white question mark	punctuation	symbols
❕	white exclamation mark	punctuation	symbols
❗	red exclamation mark	punctuation	symbols
〰️	wavy dash	punctuation	symbols
💱	currency exchange	currency	symbols
💲	heavy dollar sign	currency	symbols
⚕️	medical symbol	other symbol	symbols
♻️	recycling symbol	other symbol	symbols
⚜️	fleur-de-lis	other symbol	symbols
🔱	trident emblem	other symbol	symbols
📛	name badge	other symbol	symbols
🔰	Japanese symbol for beginner	other symbol	symbols
⭕	hollow red circle	other symbol	symbols
✅	check mark button	other symbol	symbols
☑️	check box with check	other symbol	symbols
✔️	check mark	other symbol	symbols
❌	cross mark	other symbol	symbols
❎	cross mark button	other symbol	symbols
➰	curly loop	other symbol	symbols
➿	double curly loop	other symbol	symbols
〽️	part alternation mark	other symbol	symbols
✳️	eight-spoked asterisk	other symbol	symbols
✴️	eight-pointed star	other symbol	symbols
❇️	sparkle	other symbol	symbols
©️	copyright	other symbol	symbols
®️	registered	other symbol	symbols
™️	trade mark	other symbol	symbols
🫟	splatter	other symbol	symbols
#️⃣	keycap: #	keycap	symbols
*️⃣	keycap: *	keycap	symbols
0️⃣	keycap: 0	keycap	symbols
1️⃣	keycap: 1	keycap	symbols
2️⃣	keycap: 2	keycap	symbols
3️⃣	keycap: 3	keycap	symbols
4️⃣	keycap: 4	keycap	symbols
5️⃣	keycap: 5	keycap	symbols
6️⃣	keycap: 6	keycap	symbols
7️⃣	keycap: 7	keycap	symbols
8️⃣	keycap: 8	keycap	symbols
9️⃣	keycap: 9	keycap	symbols
🔟	keycap: 10	keycap	symbols
🔠	input latin uppercase	alphanum	symbols
🔡	input latin lowercase	alphanum	symbols
🔢	input numbers	alphanum	symbols
🔣	input symbols	alphanum	symbols
🔤	input latin letters	alphanum	symbols
🅰️	A button (blood type)	alphanum	symbols
🆎	AB button (blood type)	alphanum	symbols
🅱️	B button (blood type)	alphanum	symbols
🆑	CL button	alphanum	symbols
🆒	COOL button	alphanum	symbols
🆓	FREE button	alphanum	symbols
ℹ️	information	alphanum	symbols
🆔	ID button	alphanum	symbols
Ⓜ️	circled M	alphanum	symbols
🆕	NEW button	alphanum	symbols
🆖	NG button	alphanum	symbols
🅾️	O button (blood type)	alphanum	symbols
🆗	OK button	alphanum	symbols
🅿️	P button	alphanum	symbols
🆘	SOS button	alphanum	symbols
🆙	UP! button	alphanum	symbols
🆚	VS button	alphanum	symbols
🈁	Japanese “here” button	alphanum	symbols
🈂️	Japanese “service charge” button	alphanum	symbols
🈷️	Japanese “monthly amount” button	alphanum	symbols
🈶	Japanese “not free of charge” button	alphanum	symbols
🈯	Japanese “reserved” button	alphanum	symbols
🉐	Japanese “bargain” button	alphanum	symbols
🈹	Japanese “discount” button	alphanum	symbols
🈚	Japanese “free of charge” button	alphanum	symbols
🈲	Japanese “prohibited” button	alphanum	symbols
🉑	Japanese “acceptable” button	alphanum	symbols
🈸	Japanese “application” button	alphanum	symbols
🈴	Japanese “passing grade” button	alphanum	symbols
🈳	Japanese “vacancy” button	alphanum	symbols
㊗️	Japanese “congratulations” button	alphanum	symbols
㊙️	Japanese “secret” button	alphanum	symbols
🈺	Japanese “open for business” button	alphanum	symbols
🈵	Japanese “no vacancy” button	alphanum	symbols
🔴	red circle	geometric	symbols
🟠	orange circle	geometric	symbols
🟡	yellow circle	geometric	symbols
🟢	green circle	geometric	symbols
🔵	blue circle	geometric	symbols
🟣	purple circle	geometric	symbols
🟤	brown circle	geometric	symbols
⚫	black circle	geometric	symbols
⚪	white circle	geometric	symbols
🟥	red square	geometric	symbols
🟧	orange square	geometric	symbols
🟨	yellow square	geometric	symbols
🟩	green square	geometric	symbols
🟦	blue square	geometric	symbols
🟪	purple square	geometric	symbols
🟫	brown square	geometric	symbols
⬛	black large square	geometric	symbols
⬜	white large square	geometric	symbols
◼️	black medium square	geometric	symbols
◻️	white medium square	geometric	symbols
◾	black medium-small square	geometric	symbols
◽	white medium-small square	geometric	symbols
▪️	black small square	geometric	symbols
▫️	white small square	geometric	symbols
🔶	large orange diamond	geometric	symbols
🔷	large blue diamond	geometric	symbols
🔸	small orange diamond	geometric	symbols
🔹	small blue diamond	geometric	symbols
🔺	red triangle pointed up	geometric	symbols
🔻	red triangle pointed down	geometric	symbols
💠	diamond with a dot	geometric	symbols
🔘	radio button	geometric	symbols
🔳	white square button	geometric	symbols
🔲	black square button	geometric	symbols
🏁	chequered flag	flag	flags
🚩	triangular flag	flag	flags
🎌	crossed flags	flag	flags
🏴	black flag	flag	flags
🏳️	white flag	flag	flags
🏳️‍🌈	rainbow flag	flag	flags
🏳️‍⚧️	transgender flag	flag	flags
🏴‍☠️	pirate flag	flag	flags
🇦🇨	flag: Ascension Island	country flag	flags
🇦🇩	flag: Andorra	country flag	flags
🇦🇪	flag: United Arab Emirates	country flag	flags
🇦🇫	flag: Afghanistan	country flag	flags
🇦🇬	flag: Antigua & Barbuda	country flag	flags
🇦🇮	flag: Anguilla	country flag	flags
🇦🇱	flag: Albania	country flag	flags
🇦🇲	flag: Armenia	country flag	flags
🇦🇴	flag: Angola	country flag	flags
🇦🇶	flag: Antarctica	country flag	flags
🇦🇷	flag: Argentina	country flag	flags
🇦🇸	flag: American Samoa	country flag	flags
🇦🇹	flag: Austria	country flag	flags
🇦🇺	flag: Australia	country flag	flags
🇦🇼	flag: Aruba	country flag	flags
🇦🇽	flag: Åland Islands	country flag	flags
🇦🇿	flag: Azerbaijan	country flag	flags
🇧🇦	flag: Bosnia & Herzegovina	country flag	flags
🇧🇧	flag: Barbados	country flag	flags
🇧🇩	flag: Bangladesh	country flag	flags
🇧🇪	flag: Belgium	country flag	flags
🇧🇫	flag: Burkina Faso	country flag	flags
🇧🇬	flag: Bulgaria	country flag	flags
🇧🇭	flag: Bahrain	country flag	flags
🇧🇮	flag: Burundi	country flag	flags
🇧🇯	flag: Benin	country flag	flags
🇧🇱	flag: St. Barthélemy	country flag	flags
🇧🇲	flag: Bermuda	country flag	flags
🇧🇳	flag: Brunei	country flag	flags
🇧🇴	flag: Bolivia	country flag	flags
🇧🇶	flag: Caribbean Netherlands	country flag	flags
🇧🇷	flag: Brazil	country flag	flags
🇧🇸	flag: Bahamas	country flag	flags
🇧🇹	flag: Bhutan	country flag	flags
🇧🇻	flag: Bouvet Island	country flag	flags
🇧🇼	flag: Botswana	country flag	flags
🇧🇾	flag: Belarus	country flag	flags
🇧🇿	flag: Belize	country flag	flags
🇨🇦	flag: Canada	country flag	flags
🇨🇨	flag: Cocos (Keeling) Islands	country flag	flags
🇨🇩	flag: Congo - Kinshasa	country flag	flags
🇨🇫	flag: Central African Republic	country flag	flags
🇨🇬	flag: Congo - Brazzaville	country flag	flags
🇨🇭	flag: Switzerland	country flag	flags
🇨🇮	flag: Côte d’Ivoire	country flag	flags
🇨🇰	flag: Cook Islands	country flag	flags
🇨🇱	flag: Chile	country flag	flags
🇨🇲	flag: Cameroon	country flag	flags
🇨🇳	flag: China	country flag	flags
🇨🇴	flag: Colombia	country flag	flags
🇨🇵	flag: Clipperton Island	country flag	flags
🇨🇶	flag: Sark	country flag	flags
🇨🇷	flag: Costa Rica	country flag	flags
🇨🇺	flag: Cuba	country flag	flags
🇨🇻	flag: Cape Verde	country flag	flags
🇨🇼	flag: Curaçao	country flag	flags
🇨🇽	flag: Christmas Island	country flag	flags
🇨🇾	flag: Cyprus	country flag	flags
🇨🇿	flag: Czechia	country flag	flags
🇩🇪	flag: Germany	country flag	flags
🇩🇬	flag: Diego Garcia	country flag	flags
🇩🇯	flag: Djibouti	country flag	flags
🇩🇰	flag: Denmark	country flag	flags
🇩🇲	flag: Dominica	country flag	flags
🇩🇴	flag: Dominican Republic	country flag	flags
🇩🇿	flag: Algeria	country flag	flags
🇪🇦	flag: Ceuta & Melilla	country flag	flags
🇪🇨	flag: Ecuador	country flag	flags
🇪🇪	flag: Estonia	country flag	flags
🇪🇬	flag: Egypt	country flag	flags
🇪🇭	flag: Western Sahara	country flag	flags
🇪🇷	flag: Eritrea	country flag	flags
🇪🇸	flag: Spain	country flag	flags
🇪🇹	flag: Ethiopia	country flag	flags
🇪🇺	flag: European Union	country flag	flags
🇫🇮	flag: Finland	country flag	flags
🇫🇯	flag: Fiji	country flag	flags
🇫🇰	flag: Falkland Islands	country flag	flags
🇫🇲	flag: Micronesia	country flag	flags
🇫🇴	flag: Faroe Islands	country flag	flags
🇫🇷	flag: France	country flag	flags
🇬🇦	flag: Gabon	country flag	flags
🇬🇧	flag: United Kingdom	country flag	flags
🇬🇩	flag: Grenada	country flag	flags
🇬🇪	flag: Georgia	country flag	flags
🇬🇫	flag: French Guiana	country flag	flags
🇬🇬	flag: Guernsey	country flag	flags
🇬🇭	flag: Ghana	country flag	flags
🇬🇮	flag: Gibraltar	country flag	flags
🇬🇱	flag: Greenland	country flag	flags
🇬🇲	flag: Gambia	country flag	flags
🇬🇳	flag: Guinea	country flag	flags
🇬🇵	flag: Guadeloupe	country flag	flags
🇬🇶	flag: Equatorial Guinea	country flag	flags
🇬🇷	flag: Greece	country flag	flags
🇬🇸	flag: South Georgia & South Sandwich Islands	country flag	flags
🇬🇹	flag: Guatemala	country flag	flags
🇬🇺	flag: Guam	country flag	flags
🇬🇼	flag: Guinea-Bissau	country flag	flags
🇬🇾	flag: Guyana	country flag	flags
🇭🇰	flag: Hong Kong SAR China	country flag	flags
🇭🇲	flag: Heard & McDonald Islands	country flag	flags
🇭🇳	flag: Honduras	country flag	flags
🇭🇷	flag: Croatia	country flag	flags
🇭🇹	flag: Haiti	country flag	flags
🇭🇺	flag: Hungary	country flag	flags
🇮🇨	flag: Canary Islands	country flag	flags
🇮🇩	flag: Indonesia	country flag	flags
🇮🇪	flag: Ireland	country flag	flags
🇮🇱	flag: Israel	country flag	flags
🇮🇲	flag: Isle of Man	country flag	flags
🇮🇳	flag: India	country flag	flags
🇮🇴	flag: British Indian Ocean Territory	country flag	flags
🇮🇶	flag: Iraq	country flag	flags
🇮🇷	flag: Iran	country flag	flags
🇮🇸	flag: Iceland	country flag	flags
🇮🇹	flag: Italy	country flag	flags
🇯🇪	flag: Jersey	country flag	flags
🇯🇲	flag: Jamaica	country flag	flags
🇯🇴	flag: Jordan	country flag	flags
🇯🇵	flag: Japan	country flag	flags
🇰🇪	flag: Kenya	country flag	flags
🇰🇬	flag: Kyrgyzstan	country flag	flags
🇰🇭	flag: Cambodia	country flag	flags
🇰🇮	flag: Kiribati	country flag	flags
🇰🇲	flag: Comoros	country flag	flags
🇰🇳	flag: St. Kitts & Nevis	country flag	flags
🇰🇵	flag: North Korea	country flag	flags
🇰🇷	flag: South Korea	country flag	flags
🇰🇼	flag: Kuwait	country flag	flags
🇰🇾	flag: Cayman Islands	country flag	flags
🇰🇿	flag: Kazakhstan	country flag	flags
🇱🇦	flag: Laos	country flag	flags
🇱🇧	flag: Lebanon	country flag	flags
🇱🇨	flag: St. Lucia	country flag	flags
🇱🇮	flag: Liechtenstein	country flag	flags
🇱🇰	flag: Sri Lanka	country flag	flags
🇱🇷	flag: Liberia	country flag	flags
🇱🇸	flag: Lesotho	country flag	flags
🇱🇹	flag: Lithuania	country flag	flags
🇱🇺	flag: Luxembourg	country flag	flags
🇱🇻	flag: Latvia	country flag	flags
🇱🇾	flag: Libya	country flag	flags
🇲🇦	flag: Morocco	country flag	flags
🇲🇨	flag: Monaco	country flag	flags
🇲🇩	flag: Moldova	country flag	flags
🇲🇪	flag: Montenegro	country flag	flags
🇲🇫	flag: St. Martin	country flag	flags
🇲🇬	flag: Madagascar	country flag	flags
🇲🇭	flag: Marshall Islands	country flag	flags
🇲🇰	flag: North Macedonia	country flag	flags
🇲🇱	flag: Mali	country flag	flags
🇲🇲	flag: Myanmar (Burma)	country flag	flags
🇲🇳	flag: Mongolia	country flag	flags
🇲🇴	flag: Macao SAR China	country flag	flags
🇲🇵	flag: Northern Mariana Islands	country flag	flags
🇲🇶	flag: Martinique	country flag	flags
🇲🇷	flag: Mauritania	country flag	flags
🇲🇸	flag: Montserrat	country flag	flags
🇲🇹	flag: Malta	country flag	flags
🇲🇺	flag: Mauritius	country flag	flags
🇲🇻	flag: Maldives	country flag	flags
🇲🇼	flag: Malawi	country flag	flags
🇲🇽	flag: Mexico	country flag	flags
🇲🇾	flag: Malaysia	country flag	flags
🇲🇿	flag: Mozambique	country flag	flags
🇳🇦	flag: Namibia	country flag	flags
🇳🇨	flag: New Caledonia	country flag	flags
🇳🇪	flag: Niger	country flag	flags
🇳🇫	flag: Norfolk Island	country flag	flags
🇳🇬	flag: Nigeria	country flag	flags
🇳🇮	flag: Nicaragua	country flag	flags
🇳🇱	flag: Netherlands	country flag	flags
🇳🇴	flag: Norway	country flag	flags
🇳🇵	flag: Nepal	country flag	flags
🇳🇷	flag: Nauru	country flag	flags
🇳🇺	flag: Niue	country flag	flags
🇳🇿	flag: New Zealand	country flag	flags
🇴🇲	flag: Oman	country flag	flags
🇵🇦	flag: Panama	country flag	flags
🇵🇪	flag: Peru	country flag	flags
🇵🇫	flag: French Polynesia	country flag	flags
🇵🇬	flag: Papua New Guinea	country flag	flags
🇵🇭	flag: Philippines	country flag	flags
🇵🇰	flag: Pakistan	country flag	flags
🇵🇱	flag: Poland	country flag	flags
🇵🇲	flag: St. Pierre & Miquelon	country flag	flags
🇵🇳	flag: Pitcairn Islands	country flag	flags
🇵🇷	flag: Puerto Rico	country flag	flags
🇵🇸	flag: Palestinian Territories	country flag	flags
🇵🇹	flag: Portugal	country flag	flags
🇵🇼	flag: Palau	country flag	flags
🇵🇾	flag: Paraguay	country flag	flags
🇶🇦	flag: Qatar	country flag	flags
🇷🇪	flag: Réunion	country flag	flags
🇷🇴	flag: Romania	country flag	flags
🇷🇸	flag: Serbia	country flag	flags
🇷🇺	flag: Russia	country flag	flags
🇷🇼	flag: Rwanda	country flag	flags
🇸🇦	flag: Saudi Arabia	country flag	flags
🇸🇧	flag: Solomon Islands	country flag	flags
🇸🇨	flag: Seychelles	country flag	flags
🇸🇩	flag: Sudan	country flag	flags
🇸🇪	flag: Sweden	country flag	flags
🇸🇬	flag: Singapore	country flag	flags
🇸🇭	flag: St. Helena	country flag	flags
🇸🇮	flag: Slovenia	country flag	flags
🇸🇯	flag: Svalbard & Jan Mayen	country flag	flags
🇸🇰	flag: Slovakia	country flag	flags
🇸🇱	flag: Sierra Leone	country flag	flags
🇸🇲	flag: San Marino	country flag	flags
🇸🇳	flag: Senegal	country flag	flags
🇸🇴	flag: Somalia	country flag	flags
🇸🇷	flag: Suriname	country flag	flags
🇸🇸	flag: South Sudan	country flag	flags
🇸🇹	flag: São Tomé & Príncipe	country flag	flags
🇸🇻	flag: El Salvador	country flag	flags
🇸🇽	flag: Sint Maarten	country flag	flags
🇸🇾	flag: Syria	country flag	flags
🇸🇿	flag: Eswatini	country flag	flags
🇹🇦	flag: Tristan da Cunha	country flag	flags
🇹🇨	flag: Turks & Caicos Islands	country flag	flags
🇹🇩	flag: Chad	country flag	flags
🇹🇫	flag: French Southern Territories	country flag	flags
🇹🇬	flag: Togo	country flag	flags
🇹🇭	flag: Thailand	country flag	flags
🇹🇯	flag: Tajikistan	country flag	flags
🇹🇰	flag: Tokelau	country flag	flags
🇹🇱	flag: Timor-Leste	country flag	flags
🇹🇲	flag: Turkmenistan	country flag	flags
🇹🇳	flag: Tunisia	country flag	flags
🇹🇴	flag: Tonga	country flag	flags
🇹🇷	flag: Türkiye	country flag	flags
🇹🇹	flag: Trinidad & Tobago	country flag	flags
🇹🇻	flag: Tuvalu	country flag	flags
🇹🇼	flag: Taiwan	country flag	flags
🇹🇿	flag: Tanzania	country flag	flags
🇺🇦	flag: Ukraine	country flag	flags
🇺🇬	flag: Uganda	country flag	flags
🇺🇲	flag: U.S. Outlying Islands	country flag	flags
🇺🇳	flag: United Nations	country flag	flags
🇺🇸	flag: United States	country flag	flags
🇺🇾	flag: Uruguay	country flag	flags
🇺🇿	flag: Uzbekistan	country flag	flags
🇻🇦	flag: Vatican City	country flag	flags
🇻🇨	flag: St. Vincent & Grenadines	country flag	flags
🇻🇪	flag: Venezuela	country flag	flags
🇻🇬	flag: British Virgin Islands	country flag	flags
🇻🇮	flag: U.S. Virgin Islands	country flag	flags
🇻🇳	flag: Vietnam	country flag	flags
🇻🇺	flag: Vanuatu	country flag	flags
🇼🇫	flag: Wallis & Futuna	country flag	flags
🇼🇸	flag: Samoa	country flag	flags
🇽🇰	flag: Kosovo	country flag	flags
🇾🇪	flag: Yemen	country flag	flags
🇾🇹	flag: Mayotte	country flag	flags
🇿🇦	flag: South Africa	country flag	flags
🇿🇲	flag: Zambia	country flag	flags
🇿🇼	flag: Zimbabwe	country flag	flags
🏴󠁧󠁢󠁥󠁮󠁧󠁿	flag: England	subdivision flag	flags
🏴󠁧󠁢󠁳󠁣󠁴󠁿	flag: Scotland	subdivision flag	flags
🏴󠁧󠁢󠁷󠁬󠁳󠁿	flag: Wales	subdivision flag	flags`

var list = null

function all() {
    if (list) return list
    list = []
    var lines = raw.split("\n")
    for (var i = 0; i < lines.length; i++) {
        var p = lines[i].split("\t")
        list.push({ kind: "emoji", glyph: p[0], name: p[1], words: (p[1] + " " + p[2]).toLowerCase(), group: p[3] })
    }
    return list
}
