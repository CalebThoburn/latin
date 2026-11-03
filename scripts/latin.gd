class_name Latin
extends RefCounted
## Vocabulary, morphology (stem + ending) and a small sentence parser.
## No English glosses: feedback is purely grammatical.
##
## Stem rules:
##  nouns - the stem is the genitive singular minus its ending (puella, puellae -> puell-;
##          rēx, rēgis -> rēg-). Where the nominative singular isn't stem + ending
##          (puer, ager, rēx, mīles...) the bare stem piece *is* the nominative ("bare_nom").
##  verbs - 1st/2nd/4th conj.: the infinitive minus -re (amā-, vidē-, audī-);
##          3rd conj.: the infinitive minus -ere (dūc-), unless the 3rd plural has
##          -iunt (capiunt): then the stem ends in a small (i) (capi-).

const STEMS := {
	# ---- nouns, 1st declension
	"puell": {"pos": "noun", "decl": 1, "dict": "puella, puellae (f.)"},
	"agricol": {"pos": "noun", "decl": 1, "dict": "agricola, agricolae (m.)"},
	"naut": {"pos": "noun", "decl": 1, "dict": "nauta, nautae (m.)"},
	"poet": {"pos": "noun", "decl": 1, "dict": "poēta, poētae (m.)"},
	"regin": {"pos": "noun", "decl": 1, "dict": "rēgīna, rēgīnae (f.)"},
	"fili": {"pos": "noun", "decl": 1, "dict": "fīlia, fīliae (f.)"},
	"femin": {"pos": "noun", "decl": 1, "dict": "fēmina, fēminae (f.)"},
	"cas": {"pos": "noun", "decl": 1, "dict": "casa, casae (f.)"},
	"aqu": {"pos": "noun", "decl": 1, "dict": "aqua, aquae (f.)"},
	"silv": {"pos": "noun", "decl": 1, "dict": "silva, silvae (f.)"},
	"insul": {"pos": "noun", "decl": 1, "dict": "īnsula, īnsulae (f.)"},
	"terr": {"pos": "noun", "decl": 1, "dict": "terra, terrae (f.)"},
	"vi": {"pos": "noun", "decl": 1, "dict": "via, viae (f.)"},
	"caud": {"pos": "noun", "decl": 1, "dict": "cauda, caudae (f.)"},
	"uv": {"pos": "noun", "decl": 1, "dict": "ūva, ūvae (f.)"},
	# ---- 2nd declension
	"puer": {"pos": "noun", "decl": 2, "dict": "puer, puerī (m.)", "bare_nom": true, "nom": "puer"},
	"vir": {"pos": "noun", "decl": 2, "dict": "vir, virī (m.)", "bare_nom": true, "nom": "vir"},
	"agr": {"pos": "noun", "decl": 2, "dict": "ager, agrī (m.)", "bare_nom": true, "nom": "ager"},
	"magistr": {"pos": "noun", "decl": 2, "dict": "magister, magistrī (m.)", "bare_nom": true, "nom": "magister"},
	"domin": {"pos": "noun", "decl": 2, "dict": "dominus, dominī (m.)"},
	"equ": {"pos": "noun", "decl": 2, "dict": "equus, equī (m.)"},
	"serv": {"pos": "noun", "decl": 2, "dict": "servus, servī (m.)"},
	"amic": {"pos": "noun", "decl": 2, "dict": "amīcus, amīcī (m.)"},
	"lup": {"pos": "noun", "decl": 2, "dict": "lupus, lupī (m.)"},
	"discipul": {"pos": "noun", "decl": 2, "dict": "discipulus, discipulī (m.)"},
	"riv": {"pos": "noun", "decl": 2, "dict": "rīvus, rīvī (m.)"},
	"case": {"pos": "noun", "decl": 2, "dict": "cāseus, cāseī (m.)"},
	"pocul": {"pos": "noun", "decl": 2, "dict": "pōculum, pōculī (n.)", "neuter": true},
	# sevērus, -a, -um is an adjective; here it's used as a noun: "the stern man"
	"sever": {"pos": "noun", "decl": 2, "dict": "sevērus, sevērī (m.)"},
	# ---- 3rd declension (the bare stem piece is the nominative singular)
	"reg": {"pos": "noun", "decl": 3, "dict": "rēx, rēgis (m.)", "bare_nom": true, "nom": "rēx"},
	"milit": {"pos": "noun", "decl": 3, "dict": "mīles, mīlitis (m.)", "bare_nom": true, "nom": "mīles"},
	"matr": {"pos": "noun", "decl": 3, "dict": "māter, mātris (f.)", "bare_nom": true, "nom": "māter"},
	"patr": {"pos": "noun", "decl": 3, "dict": "pater, patris (m.)", "bare_nom": true, "nom": "pater"},
	"fratr": {"pos": "noun", "decl": 3, "dict": "frāter, frātris (m.)", "bare_nom": true, "nom": "frāter"},
	"soror": {"pos": "noun", "decl": 3, "dict": "soror, sorōris (f.)", "bare_nom": true, "nom": "soror"},
	"uxor": {"pos": "noun", "decl": 3, "dict": "uxor, uxōris (f.)", "bare_nom": true, "nom": "uxor"},
	"homin": {"pos": "noun", "decl": 3, "dict": "homō, hominis (m.)", "bare_nom": true, "nom": "homō"},
	"leon": {"pos": "noun", "decl": 3, "dict": "leō, leōnis (m.)", "bare_nom": true, "nom": "leō"},
	"imperator": {"pos": "noun", "decl": 3, "dict": "imperātor, imperātōris (m.)", "bare_nom": true, "nom": "imperātor"},
	"can": {"pos": "noun", "decl": 3, "dict": "canis, canis (m./f.)", "bare_nom": true, "nom": "canis"},
	"greg": {"pos": "noun", "decl": 3, "dict": "grex, gregis (m.)", "bare_nom": true, "nom": "grex"},
	"harundin": {"pos": "noun", "decl": 3, "dict": "harundō, harundinis (f.)", "bare_nom": true, "nom": "harundō"},
	"pauper": {"pos": "noun", "decl": 3, "dict": "pauper, pauperis (m.)", "bare_nom": true, "nom": "pauper"},
	# auris is an i-stem: its genitive plural is aurium, not aurum
	"carmin": {"pos": "noun", "decl": 3, "dict": "carmen, carminis (n.)", "bare_nom": true, "nom": "carmen", "neuter": true},
	"aur": {"pos": "noun", "decl": 3, "dict": "auris, auris (f.)", "bare_nom": true, "nom": "auris", "istem": true},
	# neuter: the bare piece is nominative AND accusative singular (lītus); plural -a
	"litor": {"pos": "noun", "decl": 3, "dict": "lītus, lītoris (n.)", "bare_nom": true, "nom": "lītus", "neuter": true},
	# indeclinable: one form for every use (here nominative or accusative)
	"nihil": {"pos": "noun", "decl": 0, "dict": "nihil (n., indecl.)", "bare_nom": true, "nom": "nihil", "neuter": true, "indecl": true},
	# ---- 4th declension
	"man": {"pos": "noun", "decl": 4, "dict": "manus, manūs (f.)"},
	"exercit": {"pos": "noun", "decl": 4, "dict": "exercitus, exercitūs (m.)"},
	"fruct": {"pos": "noun", "decl": 4, "dict": "frūctus, frūctūs (m.)"},
	"senat": {"pos": "noun", "decl": 4, "dict": "senātus, senātūs (m.)"},
	"port": {"pos": "noun", "decl": 4, "dict": "portus, portūs (m.)"},
	# ---- 5th declension
	"r": {"pos": "noun", "decl": 5, "dict": "rēs, reī (f.)"},
	"di": {"pos": "noun", "decl": 5, "dict": "diēs, diēī (m.)"},
	"sp": {"pos": "noun", "decl": 5, "dict": "spēs, speī (f.)"},
	"fid": {"pos": "noun", "decl": 5, "dict": "fidēs, fideī (f.)"},

	# verbs: "cons" is the solid round body, "vowel" is the knob on its right,
	# "long" is the body with its macrons, "vclass" is the stem type: a | e | i | (i) | cons
	# ---- 1st conjugation: ā-stems
	"ama": {"pos": "verb", "trans": true, "vclass": "a", "cons": "am", "long": "am", "vowel": "a", "dict": "amō, amāre"},
	"porta": {"pos": "verb", "trans": true, "vclass": "a", "cons": "port", "long": "port", "vowel": "a", "dict": "portō, portāre"},
	"lauda": {"pos": "verb", "trans": true, "vclass": "a", "cons": "laud", "long": "laud", "vowel": "a", "dict": "laudō, laudāre"},
	"voca": {"pos": "verb", "trans": true, "vclass": "a", "cons": "voc", "long": "voc", "vowel": "a", "dict": "vocō, vocāre"},
	"specta": {"pos": "verb", "trans": true, "vclass": "a", "cons": "spect", "long": "spect", "vowel": "a", "dict": "spectō, spectāre"},
	"para": {"pos": "verb", "trans": true, "vclass": "a", "cons": "par", "long": "par", "vowel": "a", "dict": "parō, parāre"},
	"serva": {"pos": "verb", "trans": true, "vclass": "a", "cons": "serv", "long": "serv", "vowel": "a", "dict": "servō, servāre"},
	"neca": {"pos": "verb", "trans": true, "vclass": "a", "cons": "nec", "long": "nec", "vowel": "a", "dict": "necō, necāre"},
	"oppugna": {"pos": "verb", "trans": true, "vclass": "a", "cons": "oppugn", "long": "oppugn", "vowel": "a", "dict": "oppugnō, oppugnāre"},
	"labora": {"pos": "verb", "trans": false, "vclass": "a", "cons": "labor", "long": "labōr", "vowel": "a", "dict": "labōrō, labōrāre"},
	"ambula": {"pos": "verb", "trans": false, "vclass": "a", "cons": "ambul", "long": "ambul", "vowel": "a", "dict": "ambulō, ambulāre"},
	"naviga": {"pos": "verb", "trans": false, "vclass": "a", "cons": "navig", "long": "nāvig", "vowel": "a", "dict": "nāvigō, nāvigāre"},
	"pugna": {"pos": "verb", "trans": false, "vclass": "a", "cons": "pugn", "long": "pugn", "vowel": "a", "dict": "pugnō, pugnāre"},
	"bala": {"pos": "verb", "trans": false, "vclass": "a", "cons": "bal", "long": "bāl", "vowel": "a", "dict": "bālō, bālāre"},
	"erra": {"pos": "verb", "trans": false, "vclass": "a", "cons": "err", "long": "err", "vowel": "a", "dict": "errō, errāre"},
	"fla": {"pos": "verb", "trans": false, "vclass": "a", "cons": "fl", "long": "fl", "vowel": "a", "dict": "flō, flāre"},
	"inspira": {"pos": "verb", "trans": true, "vclass": "a", "cons": "inspir", "long": "īnspīr", "vowel": "a", "dict": "īnspīrō, īnspīrāre"},
	"iuva": {"pos": "verb", "trans": true, "vclass": "a", "cons": "iuv", "long": "iuv", "vowel": "a", "dict": "iuvō, iuvāre"},
	# verbs with a dative (to whom): a purple cable for the one it's given / shown / told to
	"da": {"pos": "verb", "trans": true, "dat": true, "short": true, "vclass": "a", "cons": "d", "long": "d", "vowel": "a", "dict": "dō, dare"},
	"monstra": {"pos": "verb", "trans": true, "dat": true, "vclass": "a", "cons": "monstr", "long": "mōnstr", "vowel": "a", "dict": "mōnstrō, mōnstrāre"},
	"narra": {"pos": "verb", "trans": true, "dat": true, "vclass": "a", "cons": "narr", "long": "nārr", "vowel": "a", "dict": "nārrō, nārrāre"},
	"habita": {"pos": "verb", "trans": false, "vclass": "a", "cons": "habit", "long": "habit", "vowel": "a", "dict": "habitō, habitāre"},
	# ---- 2nd conjugation: ē-stems
	"vide": {"pos": "verb", "trans": true, "vclass": "e", "cons": "vid", "long": "vid", "vowel": "e", "dict": "videō, vidēre"},
	"habe": {"pos": "verb", "trans": true, "vclass": "e", "cons": "hab", "long": "hab", "vowel": "e", "dict": "habeō, habēre"},
	"mone": {"pos": "verb", "trans": true, "vclass": "e", "cons": "mon", "long": "mon", "vowel": "e", "dict": "moneō, monēre"},
	"time": {"pos": "verb", "trans": true, "vclass": "e", "cons": "tim", "long": "tim", "vowel": "e", "dict": "timeō, timēre"},
	"tene": {"pos": "verb", "trans": true, "vclass": "e", "cons": "ten", "long": "ten", "vowel": "e", "dict": "teneō, tenēre"},
	"doce": {"pos": "verb", "trans": true, "vclass": "e", "cons": "doc", "long": "doc", "vowel": "e", "dict": "doceō, docēre"},
	"terre": {"pos": "verb", "trans": true, "vclass": "e", "cons": "terr", "long": "terr", "vowel": "e", "dict": "terreō, terrēre"},
	"move": {"pos": "verb", "trans": true, "vclass": "e", "cons": "mov", "long": "mov", "vowel": "e", "dict": "moveō, movēre"},
	"iube": {"pos": "verb", "trans": true, "vclass": "e", "cons": "iub", "long": "iub", "vowel": "e", "dict": "iubeō, iubēre"},
	"mane": {"pos": "verb", "trans": false, "vclass": "e", "cons": "man", "long": "man", "vowel": "e", "dict": "maneō, manēre"},
	"sede": {"pos": "verb", "trans": false, "vclass": "e", "cons": "sed", "long": "sed", "vowel": "e", "dict": "sedeō, sedēre"},
	"tace": {"pos": "verb", "trans": false, "vclass": "e", "cons": "tac", "long": "tac", "vowel": "e", "dict": "taceō, tacēre"},
	# ---- 3rd conjugation: consonant stems (-ere, -unt)
	"duc": {"pos": "verb", "trans": true, "vclass": "cons", "cons": "duc", "long": "dūc", "vowel": "", "dict": "dūcō, dūcere"},
	"mitt": {"pos": "verb", "trans": true, "vclass": "cons", "cons": "mitt", "long": "mitt", "vowel": "", "dict": "mittō, mittere"},
	"leg": {"pos": "verb", "trans": true, "vclass": "cons", "cons": "leg", "long": "leg", "vowel": "", "dict": "legō, legere"},
	"scrib": {"pos": "verb", "trans": true, "vclass": "cons", "cons": "scrib", "long": "scrīb", "vowel": "", "dict": "scrībō, scrībere"},
	"dic": {"pos": "verb", "trans": true, "vclass": "cons", "cons": "dic", "long": "dīc", "vowel": "", "dict": "dīcō, dīcere"},
	"bib": {"pos": "verb", "trans": true, "vclass": "cons", "cons": "bib", "long": "bib", "vowel": "", "dict": "bibō, bibere"},
	"vinc": {"pos": "verb", "trans": true, "vclass": "cons", "cons": "vinc", "long": "vinc", "vowel": "", "dict": "vincō, vincere"},
	"ag": {"pos": "verb", "trans": true, "vclass": "cons", "cons": "ag", "long": "ag", "vowel": "", "dict": "agō, agere"},
	"pet": {"pos": "verb", "trans": true, "vclass": "cons", "cons": "pet", "long": "pet", "vowel": "", "dict": "petō, petere"},
	"curr": {"pos": "verb", "trans": false, "vclass": "cons", "cons": "curr", "long": "curr", "vowel": "", "dict": "currō, currere"},
	"cad": {"pos": "verb", "trans": false, "vclass": "cons", "cons": "cad", "long": "cad", "vowel": "", "dict": "cadō, cadere"},
	"viv": {"pos": "verb", "trans": false, "vclass": "cons", "cons": "viv", "long": "vīv", "vowel": "", "dict": "vīvō, vīvere"},
	"lud": {"pos": "verb", "trans": false, "vclass": "cons", "cons": "lud", "long": "lūd", "vowel": "", "dict": "lūdō, lūdere"},
	"arrig": {"pos": "verb", "trans": true, "vclass": "cons", "cons": "arrig", "long": "arrig", "vowel": "", "dict": "arrigō, arrigere"},
	"disced": {"pos": "verb", "trans": false, "vclass": "cons", "cons": "disced", "long": "discēd", "vowel": "", "dict": "discēdō, discēdere"},
	# ---- 3rd conjugation -iō verbs: -ere but -iunt, so the stem ends in a small (i)
	"capi": {"pos": "verb", "trans": true, "vclass": "(i)", "cons": "cap", "long": "cap", "vowel": "i", "dict": "capiō, capere"},
	"faci": {"pos": "verb", "trans": true, "vclass": "(i)", "cons": "fac", "long": "fac", "vowel": "i", "dict": "faciō, facere"},
	"iaci": {"pos": "verb", "trans": true, "vclass": "(i)", "cons": "iac", "long": "iac", "vowel": "i", "dict": "iaciō, iacere"},
	"cupi": {"pos": "verb", "trans": true, "vclass": "(i)", "cons": "cup", "long": "cup", "vowel": "i", "dict": "cupiō, cupere"},
	"accipi": {"pos": "verb", "trans": true, "vclass": "(i)", "cons": "accip", "long": "accip", "vowel": "i", "dict": "accipiō, accipere"},
	"rapi": {"pos": "verb", "trans": true, "vclass": "(i)", "cons": "rap", "long": "rap", "vowel": "i", "dict": "rapiō, rapere"},
	"aspici": {"pos": "verb", "trans": true, "vclass": "(i)", "cons": "aspic", "long": "aspic", "vowel": "i", "dict": "aspiciō, aspicere"},
	"fugi": {"pos": "verb", "trans": false, "vclass": "(i)", "cons": "fug", "long": "fug", "vowel": "i", "dict": "fugiō, fugere"},
	# ---- 4th conjugation: ī-stems
	"audi": {"pos": "verb", "trans": true, "vclass": "i", "cons": "aud", "long": "aud", "vowel": "i", "dict": "audiō, audīre"},
	"sci": {"pos": "verb", "trans": true, "vclass": "i", "cons": "sc", "long": "sc", "vowel": "i", "dict": "sciō, scīre"},
	"senti": {"pos": "verb", "trans": true, "vclass": "i", "cons": "sent", "long": "sent", "vowel": "i", "dict": "sentiō, sentīre"},
	"inveni": {"pos": "verb", "trans": true, "vclass": "i", "cons": "inven", "long": "inven", "vowel": "i", "dict": "inveniō, invenīre"},
	"puni": {"pos": "verb", "trans": true, "vclass": "i", "cons": "pun", "long": "pūn", "vowel": "i", "dict": "pūniō, pūnīre"},
	"custodi": {"pos": "verb", "trans": true, "vclass": "i", "cons": "custod", "long": "custōd", "vowel": "i", "dict": "custōdiō, custōdīre"},
	"muni": {"pos": "verb", "trans": true, "vclass": "i", "cons": "mun", "long": "mūn", "vowel": "i", "dict": "mūniō, mūnīre"},
	"veni": {"pos": "verb", "trans": false, "vclass": "i", "cons": "ven", "long": "ven", "vowel": "i", "dict": "veniō, venīre"},
	"dormi": {"pos": "verb", "trans": false, "vclass": "i", "cons": "dorm", "long": "dorm", "vowel": "i", "dict": "dormiō, dormīre"},

	# adjectives (1st/2nd declension): their endings come from the ADIECT. M / F / N drawers
	"bon": {"pos": "adj", "dict": "bonus, bona, bonum"},
	"mal": {"pos": "adj", "dict": "malus, mala, malum"},
	"magn": {"pos": "adj", "dict": "magnus, magna, magnum"},
	"parv": {"pos": "adj", "dict": "parvus, parva, parvum"},
	"laet": {"pos": "adj", "dict": "laetus, laeta, laetum"},

	# prepositions: a star plug for the verb, and a square (accusative) and/or a
	# triangular (ablative) plug for the noun they govern
	"ab": {"pos": "prep", "cases": ["abl"], "dict": "ā, ab (+ abl.)"},
	"ad": {"pos": "prep", "cases": ["acc"], "dict": "ad (+ acc.)"},
	"in": {"pos": "prep", "cases": ["acc", "abl"], "dict": "in (+ acc. / + abl.)"},
	# adverbs: just a star plug for the verb
	"procul": {"pos": "adv", "dict": "procul (adv.)"},
}
# ---------------------------------------------------------------- the campaign: what's unlocked at each level

static var level := 99 # the campaign level reached (99: everything unlocked, e.g. for the self-test)

## Words that become available at each level (level 1 first).
const LEVEL_WORDS := [
	# I: nominative, 3rd person: who does it (no objects yet: verbs that need none)
	["puell", "puer", "agricol", "naut", "equ", "serv", "domin", "amic", "lup", "curr", "ambula", "labora", "erra", "sede", "dormi"],
	# II: accusative: what they do it to
	["ama", "vide", "habe", "porta", "voca", "lauda", "specta", "uv", "case", "aqu", "regin", "fili", "femin", "cas", "silv", "vir",
			"discipul", "magistr", "poet", "agr", "terr", "caud", "bala", "naviga", "pugna", "tace"],
	# III: 3rd, 4th and 5th declensions
	["reg", "milit", "matr", "patr", "fratr", "soror", "uxor", "homin", "leon", "imperator", "can", "greg", "pauper", "aur",
			"man", "exercit", "fruct", "senat", "port", "r", "di", "sp", "fid", "duc", "mitt", "audi", "time", "terre", "capi", "veni"],
	# IV: neuter
	["pocul", "carmin", "litor", "nihil", "cad", "bib", "leg", "fla", "iuva"],
	# V: adjectives
	["bon", "mal", "magn", "parv", "laet", "mone", "doce", "tene", "move", "iube", "mane"],
	# VI: ablative
	["harundin", "insul", "vi", "riv", "sever", "scrib", "dic", "vinc", "ag", "pet", "viv", "lud", "fugi", "rapi", "faci", "iaci", "cupi", "accipi"],
	# VII: prepositions and adverbs
	["ab", "ad", "in", "procul", "disced", "habita", "para", "serva", "neca", "oppugna", "aspici", "arrig", "inspira"],
	# VIII: passive
	["sci", "senti", "inveni", "puni", "custodi", "muni"],
	# IX: genitive
	[],
	# X: 1st person
	[],
	# XI: 2nd person
	[],
	# XII: dative
	["da", "monstra", "narra"],
]
## Ending forms that become available at each level. (A form an earlier level
## already gave, -ae or -ō say, is there from then on in all its uses.)
const LEVEL_ENDINGS := [
	{"decl1": ["a", "ae"], "decl2": ["us", "i"], "verb": ["t", "unt"]}, # I: nominative; 3rd person
	{"decl1": ["am", "as"], "decl2": ["um", "os"]}, # II: accusative
	{"decl3": ["es", "em"], "decl4": ["us", "ūs", "um"], "decl5": ["es", "em"]}, # III: 3rd-5th declensions
	{"neut": ["a"]}, # IV: neuter
	{}, # V: adjectives (they take the I / II endings you already have, and a cap)
	{"decl1": ["ā"], "decl2": ["o"], "decl12": ["is"], "decl3": ["e"], "decl34": ["ibus"], "decl4": ["ū"], "decl5": ["ē", "ebus"]}, # VI: ablative
	{}, # VII: prepositions
	{"verb": ["itur", "untur"]}, # VIII: passive
	{"decl1": ["arum"], "decl2": ["orum"], "decl3": ["is", "um"], "decl4": ["uum"], "decl5": ["eī", "erum"]}, # IX: genitive
	{"verb": ["ō", "imus", "or", "imur"]}, # X: 1st person
	{"verb": ["is", "itis", "eris", "imini"]}, # XI: 2nd person
	{"decl3": ["i"], "decl4": ["uī"]}, # XII: dative
]
const LEVEL_ADAPTERS := {"neut_sg": 4, "neut_pl": 4, "adj": 5, "modi": 6}
const ROMAN := ["I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X", "XI", "XII", "XIII"]


static func word_unlocked(stem: String) -> bool:
	if level > LEVEL_WORDS.size():
		return true
	for L in mini(level, LEVEL_WORDS.size()):
		if stem in LEVEL_WORDS[L]:
			return true
	return false


static func ending_unlocked(cat: String, form: String) -> bool:
	if level > LEVEL_ENDINGS.size():
		return true
	for L in mini(level, LEVEL_ENDINGS.size()):
		if form in LEVEL_ENDINGS[L].get(cat, []):
			return true
	return false


static func adapter_unlocked(key: String) -> bool:
	return level >= LEVEL_ADAPTERS.get(key, 1)


## What reaching this level unlocks, for the announcement.
static func unlock_text(L: int) -> String:
	var parts := PackedStringArray()
	if L - 1 < LEVEL_ENDINGS.size():
		var forms := PackedStringArray()
		for cat in LEVEL_ENDINGS[L - 1]:
			for f in LEVEL_ENDINGS[L - 1][cat]:
				if not "-" + f in forms:
					forms.append("-" + f)
		if not forms.is_empty():
			parts.append("endings: " + " ".join(forms))
	if L - 1 < LEVEL_WORDS.size():
		var ws := PackedStringArray()
		for w in LEVEL_WORDS[L - 1]:
			ws.append(head(w))
		parts.append("words: " + ", ".join(ws))
	for a in LEVEL_ADAPTERS:
		if LEVEL_ADAPTERS[a] == L:
			parts.append("adapter: " + a)
	return "\n".join(parts)


const VCLASS_NAME := {
	"a": "ā-stem verb (1st conj.)",
	"e": "ē-stem verb (2nd conj.)",
	"i": "ī-stem verb (4th conj.)",
	"(i)": "(i)-stem verb (3rd conj. -iō)",
	"cons": "consonant-stem verb (3rd conj.)",
}

const DRAWERS := [
	{"cat": "verb", "id": "verb", "name": "ACTIVA", "endings": ["ō", "is", "t", "imus", "itis", "unt"]},
	{"cat": "verb", "id": "verbp", "name": "PASSIVA", "endings": ["or", "eris", "itur", "imur", "imini", "untur"]},
	{"cat": "decl1", "name": "DECL. I", "endings": ["a~", "a~"]},
	{"cat": "decl2", "name": "DECL. II", "endings": ["i", "u~", "o~"]},
	{"cat": "decl12", "name": "DECL. I·II", "endings": ["is", "is"]},
	{"cat": "decl3", "name": "DECL. III", "endings": ["e~", "i~", "um"]},
	{"cat": "decl4", "name": "DECL. IV", "endings": ["u~", "ūs"]},
	{"cat": "decl34", "name": "DECL. III·IV", "endings": ["ibus", "ibus"]},
	{"cat": "decl5", "name": "DECL. V", "endings": ["e~", "e~"]},
	# the neuter plural -a, one piece for every neuter (pōcula, carmina, lītora), kept by the neuter adapters
	{"cat": "neut", "name": "NEVTRA", "endings": ["a", "a", "a"]},
]
## Noun endings with a "window": a fixed first letter, and a reel you scroll to
## pick what follows it. A long vowel (ā, ū, ē) is special: the piece telescopes
## shut into just that vowel (the ablative singular).
const REELS := {
	"decl1": {"a": ["", "m", "e", "s", "rum", "ā"]},
	"decl2": {"u": ["s", "m"], "o": ["", "s", "rum"]},
	"decl3": {"e": ["m", "", "s"], "i": ["s", ""]},
	"decl4": {"u": ["s", "m", "ī", "um", "ū"]},
	"decl5": {"e": ["s", "ī", "m", "rum", "bus", "ē"]},
	"adjm": {"u": ["s", "m"], "o": ["", "s", "rum"], "i": ["", "s"]},
	"adjf": {"a": ["", "m", "e", "s", "rum", "ā"]},
	"adjn": {"i": ["", "s"]},
}
const LONG := ["ā", "ē", "ū"]


static func is_long(opt: String) -> bool:
	return opt in LONG


static func reel_form(base: String, opt: String) -> String:
	return opt if is_long(opt) else base + opt


const DRAWER_NAME := {"verb": "VERBA", "decl1": "DECL. I", "decl2": "DECL. II", "decl12": "DECL. I·II",
		"decl3": "DECL. III", "decl4": "DECL. IV", "decl34": "DECL. III·IV", "decl5": "DECL. V", "neut": "NEVTRA",
		"adjm": "ADIECT. M", "adjf": "ADIECT. F", "adjn": "ADIECT. N"}
const ADJ_GENDER := {"adjm": "m", "adjf": "f", "adjn": "n"}
const GENDER_COLOR := {"m": Color("#3fae5a"), "f": Color("#d8423a"), "n": Color("#3f7fd9")}


## A noun's gender(s): "m", "f", "n" (canis is m. or f.).
static func genders(stem: String) -> Array:
	var s: Dictionary = STEMS[stem]
	if s.get("neuter", false):
		return ["n"]
	var d: String = s["dict"]
	if d.contains("(m./f.)"):
		return ["m", "f"]
	if d.contains("(f.)"):
		return ["f"]
	return ["m"]
## An adjective's ending, read with its gender: [[case, num, gender], ...].
## -a and -ae are feminine, -us and -ōs masculine, -um masculine (accusative) or
## neuter (nominative and accusative), the neuter plural -a neuter, and the rest
## (-ī, -ō, -ōrum; -īs) masculine or neuter (or any gender).
static func adj_readings(cat: String, ending: String) -> Array:
	var out := []
	for r in NOUN_ENDINGS.get(cat, {}).get(ending, []):
		var gs: Array = ["m", "n"]
		match cat:
			"decl1": gs = ["f"]
			"decl12": gs = ["m", "f", "n"]
			"neut": gs = ["n"]
			"decl2":
				if r[0] == "nom" or r[0] == "acc":
					gs = ["m"]
		for g in gs:
			out.append([r[0], r[1], g])
	if cat == "decl2" and ending == "um":
		out.append(["nom", "sg", "n"])
		out.append(["acc", "sg", "n"])
	return out


static func adj_genders(cat: String, ending: String) -> Array:
	var gs := []
	for r in adj_readings(cat, ending):
		if not r[2] in gs:
			gs.append(r[2])
	return gs


## Endings shared by two declensions (they stick on by magnets), and which they fit.
const SHARED := {"decl12": [1, 2], "decl34": [3, 4], "neut": [2, 3]}

## Every verb ending except ō carries a small "insert" tab with a vowel on it.
const VERB_ENDINGS := {
	"ō": {"ins": "", "body": "ō", "person": 1, "num": "sg"},
	"is": {"ins": "i", "body": "s", "person": 2, "num": "sg"},
	"t": {"ins": "i", "body": "t", "person": 3, "num": "sg"},
	"imus": {"ins": "i", "body": "mus", "person": 1, "num": "pl"},
	"itis": {"ins": "i", "body": "tis", "person": 2, "num": "pl"},
	"unt": {"ins": "u", "body": "nt", "person": 3, "num": "pl"},
	# passive: the subject has the thing done to it (puer amātur: the boy is loved)
	"or": {"ins": "", "body": "or", "person": 1, "num": "sg", "voice": "pass"},
	"eris": {"ins": "e", "body": "ris", "person": 2, "num": "sg", "voice": "pass"},
	"itur": {"ins": "i", "body": "tur", "person": 3, "num": "sg", "voice": "pass"},
	"imur": {"ins": "i", "body": "mur", "person": 1, "num": "pl", "voice": "pass"},
	"imini": {"ins": "i", "body": "minī", "person": 2, "num": "pl", "voice": "pass"},
	"untur": {"ins": "u", "body": "ntur", "person": 3, "num": "pl", "voice": "pass"},
}
## Endings that are a fat cap slipping over an ā knob (no insert tab).
const CAPS := ["ō", "or"]

const NOUN_ENDINGS := {
	"decl1": {
		"a": [["nom", "sg"]],
		"ae": [["nom", "pl"], ["gen", "sg"], ["dat", "sg"]],
		"am": [["acc", "sg"]],
		"as": [["acc", "pl"]],
		"arum": [["gen", "pl"]],
		"ā": [["abl", "sg"]],
	},
	"decl2": {
		"∅": [["nom", "sg"]], # the empty ending: puer, not puerus
		"us": [["nom", "sg"]],
		"i": [["nom", "pl"], ["gen", "sg"]],
		"o": [["dat", "sg"], ["abl", "sg"]],
		"um": [["acc", "sg"]],
		"os": [["acc", "pl"]],
		"orum": [["gen", "pl"]],
	},
	"decl3": { # nom. sg. is the bare stem piece
		"is": [["gen", "sg"]],
		"i": [["dat", "sg"]],
		"em": [["acc", "sg"]],
		"e": [["abl", "sg"]],
		"es": [["nom", "pl"], ["acc", "pl"]],
		"um": [["gen", "pl"]],
	},
	"decl4": {
		"us": [["nom", "sg"]],
		"ūs": [["gen", "sg"], ["nom", "pl"], ["acc", "pl"]],
		"uī": [["dat", "sg"]],
		"um": [["acc", "sg"]],
		"ū": [["abl", "sg"]],
		"uum": [["gen", "pl"]],
	},
	"decl12": {"is": [["dat", "pl"], ["abl", "pl"]]}, # puellīs, puerīs
	"decl34": {"ibus": [["dat", "pl"], ["abl", "pl"]]}, # rēgibus, manibus
	"neut": {"a": [["nom", "pl"], ["acc", "pl"]]}, # pōcula, carmina, lītora
	"adjm": {"us": [["nom", "sg"]], "i": [["gen", "sg"], ["nom", "pl"]], "o": [["dat", "sg"], ["abl", "sg"]], "um": [["acc", "sg"]],
		"os": [["acc", "pl"]], "orum": [["gen", "pl"]], "is": [["dat", "pl"], ["abl", "pl"]]},
	"adjf": {"a": [["nom", "sg"]], "ae": [["gen", "sg"], ["dat", "sg"], ["nom", "pl"]], "am": [["acc", "sg"]], "ā": [["abl", "sg"]],
		"as": [["acc", "pl"]], "arum": [["gen", "pl"]], "is": [["dat", "pl"], ["abl", "pl"]]},
	"adjn": {"um": [["nom", "sg"], ["acc", "sg"]], "i": [["gen", "sg"]], "o": [["dat", "sg"], ["abl", "sg"]], "a": [["nom", "pl"], ["acc", "pl"]],
		"orum": [["gen", "pl"]], "is": [["dat", "pl"], ["abl", "pl"]]},
	"decl5": {
		"es": [["nom", "sg"], ["nom", "pl"], ["acc", "pl"]],
		"eī": [["gen", "sg"], ["dat", "sg"]],
		"em": [["acc", "sg"]],
		"ē": [["abl", "sg"]],
		"erum": [["gen", "pl"]],
		"ebus": [["dat", "pl"], ["abl", "pl"]],
	},
}

const ORD := {1: "1st", 2: "2nd", 3: "3rd", 4: "4th", 5: "5th"}
const NUM := {"sg": "singular", "pl": "plural"}
const CASE_NAME := {"nom": "nominative", "gen": "genitive", "dat": "dative", "acc": "accusative", "abl": "ablative"}

static func _fail(msg: String) -> Dictionary:
	return {"ok": false, "msg": msg}


static func head(stem: String) -> String:
	return STEMS[stem]["dict"].split(",")[0]


## The nominative singular a bare stem piece stands for (puer, rēx, mīles...).
static func nom_form(stem: String) -> String:
	return STEMS[stem].get("nom", stem)


static func cat_for_stem(stem: String) -> String:
	var s: Dictionary = STEMS[stem]
	if s["pos"] == "verb":
		return "verb"
	if s["pos"] == "adj":
		return "decl2"
	if s["pos"] != "noun" or s.get("indecl", false):
		return ""
	return "decl%d" % s["decl"]


## Prepositions, adverbs and indeclinables are whole words: no ending goes on.
static func takes_ending(stem: String) -> bool:
	var s: Dictionary = STEMS[stem]
	return s["pos"] in ["verb", "adj"] or (s["pos"] == "noun" and not s.get("indecl", false))


## Does this ending (of this declension) have a genitive reading?
static func has_case(cat: String, ending: String, case: String) -> bool:
	if cat == "verb" or not NOUN_ENDINGS.has(cat) or not NOUN_ENDINGS[cat].has(ending):
		return false
	for r in NOUN_ENDINGS[cat][ending]:
		if r[0] == case:
			return true
	return false


## How a verb ending physically meets a verb stem:
##  "tuck"   - the ending's insert tab slides inside the stem's vowel knob (hidden)
##  "over"   - ō is bigger than an ā knob and caps it (the a is hidden)
##  "beside" - nothing hides; the pieces sit side by side
static func join_mode(stem: String, ending: String) -> String:
	var vc: String = STEMS[stem]["vclass"]
	if ending in CAPS:
		return "over" if vc == "a" else "beside"
	var ins: String = VERB_ENDINGS[ending]["ins"]
	if vc == "a" or vc == "e":
		return "tuck"
	if (vc == "i" or vc == "(i)") and ins == "i":
		return "tuck"
	if vc == "i" and ins == "e": # audī-ris: the e tab hides in the ī knob
		return "tuck"
	if vc == "(i)" and ins == "e": # cap-eris: the e tab takes the small (i)'s place
		return "tuck"
	return "beside"


## The written (macronized) form of a verb stem + ending.
static func verb_form(stem: String, ending: String) -> String:
	var s: Dictionary = STEMS[stem]
	var e: Dictionary = VERB_ENDINGS[ending]
	var mode := join_mode(stem, ending)
	var out: String = s["long"]
	var v: String = s["vowel"]
	if s["vclass"] == "(i)" and e["ins"] == "e": # capi + eris = caperis
		return out + "e" + e["body"]
	if mode != "over" and v != "":
		var lengthen: Array = ["s"] if s.get("short", false) else ["s", "mus", "tis", "ris", "tur", "mur", "minī"] # (dō: damus, datis)
		if s["vclass"] in ["a", "e", "i"] and e["body"] in lengthen:
			v = {"a": "ā", "e": "ē", "i": "ī"}[v]
		out += v
	if mode == "beside":
		out += e["ins"]
	return out + e["body"]


## Try to glue an ending onto a stem.
static func combine(stem: String, cat: String, ending: String) -> Dictionary:
	var s: Dictionary = STEMS[stem]
	if not takes_ending(stem):
		return _fail("%s is a whole word on its own — no ending goes on it." % s["dict"])
	if s["pos"] == "verb":
		if cat != "verb":
			return _fail("%s is a verb — it takes an ending from the VERBA drawer." % s["dict"])
		var e: Dictionary = VERB_ENDINGS[ending]
		return {"ok": true, "display": s["cons"], "latin": verb_form(stem, ending),
				"readings": [{"pos": "verb", "person": e["person"], "num": e["num"], "voice": e.get("voice", "act")}]}

	if s["pos"] == "adj": # bonus, bona, bonum: the 1st declension endings (feminine) and the 2nd (masculine, neuter)
		if not cat in ["decl1", "decl2", "decl12", "neut"]:
			return _fail("%s is an adjective: -us, -a, -um. Its endings are the I and II ones (DECL. I, DECL. II, NEVTRA)." % s["dict"])
		var ra := []
		for r in adj_readings(cat, ending):
			ra.append({"pos": "adj", "case": r[0], "num": r[1], "gender": r[2]})
		return {"ok": true, "display": stem, "latin": stem + ending, "readings": ra}
	if ADJ_GENDER.has(cat):
		return _fail("Those are adjective endings — %s is a noun." % s["dict"])
	var want := "decl%d" % s["decl"]
	if cat == "verb":
		return _fail("%s is a noun — verb endings won't fit. Try the %s drawer." % [s["dict"], DRAWER_NAME[want]])
	if cat == "neut" and not s.get("neuter", false):
		return _fail("-a here is the neuter plural (pōcula, carmina) — %s isn't neuter." % s["dict"])
	if SHARED.has(cat):
		if not s["decl"] in SHARED[cat]:
			return _fail("-%s is for %s and %s declension stems — %s is %s declension." % [
					ending, ORD[SHARED[cat][0]], ORD[SHARED[cat][1]], s["dict"], ORD[s["decl"]]])
	elif cat != want:
		return _fail("%s is %s declension — its endings live in the %s drawer." % [s["dict"], ORD[s["decl"]], DRAWER_NAME[want]])
	if ending == "∅" and not s.get("bare_nom", false):
		return _fail("Only -er nouns like puer take the empty ending ∅.")
	if s.get("bare_nom", false) and s["decl"] == 2 and ending == "us": # *puerus: it goes on... and sparks off
		var r0 := _fail("%s is already nominative on its own — no -us needed." % nom_form(stem))
		r0["neuter_bad"] = true
		return r0
	# neuters: the nominative and accusative are the same; masculine/feminine
	# endings don't belong on them (they go on, spark, and fly off)
	if s.get("neuter", false) and ((s["decl"] == 3 and ending in ["em", "es"]) or (s["decl"] == 2 and ending in ["us", "os"])):
		var r := _fail("%s is neuter: -%s isn't one of its endings (neuter: nom. = acc., plural -a)." % [s["dict"], ending])
		r["neuter_bad"] = true
		return r
	if s.get("istem", false) and ending == "um":
		return _fail("%s is an i-stem: its genitive plural is %sium." % [s["dict"], stem])
	var rs := []
	for r in NOUN_ENDINGS[cat][ending]:
		rs.append({"pos": "noun", "case": r[0], "num": r[1]})
	if s.get("neuter", false) and ending == "um" and s["decl"] == 2: # pōculum: nominative too
		rs.push_front({"pos": "noun", "case": "nom", "num": "sg"})
	return {"ok": true, "display": stem, "latin": stem + ending.replace("∅", ""), "readings": rs}


## Info about one word on the table (stem may be "" for a stray ending).
static func word_info(stem: String, cat: String, ending: String) -> Dictionary:
	if stem == "":
		return {"complete": false, "stem": "", "latin": "-" + ending, "readings": [],
				"msg": "-%s is floating alone — put a stem in front of it." % ending}
	var s: Dictionary = STEMS[stem]
	if ending == "":
		if s["pos"] == "prep" or s["pos"] == "adv":
			return {"complete": true, "stem": stem, "latin": stem, "readings": [{"pos": s["pos"]}]}
		if s.get("bare_nom", false):
			var rd := [{"pos": "noun", "case": "nom", "num": "sg"}]
			if s.get("neuter", false): # neuter: nominative and accusative look the same
				rd.append({"pos": "noun", "case": "acc", "num": "sg"})
			return {"complete": true, "stem": stem, "latin": nom_form(stem), "readings": rd}
		var shown: String = (s["cons"] + s["vowel"]) if s["pos"] == "verb" else stem
		if s["pos"] == "adj":
			return {"complete": false, "stem": stem, "latin": stem + "-", "readings": [],
					"msg": "%s- needs an ending: -us / -a / -um and the rest, from the DECL. I and II drawers." % stem}
		return {"complete": false, "stem": stem, "latin": shown + "-", "readings": [],
				"msg": "%s- needs an ending — open the %s drawer." % [shown, DRAWER_NAME[cat_for_stem(stem)]]}
	var r := combine(stem, cat, ending)
	if not r["ok"]:
		return {"complete": false, "stem": stem, "latin": stem + ending, "readings": [], "msg": r["msg"]}
	return {"complete": true, "stem": stem, "latin": r["latin"], "readings": r["readings"]}


static func reading_tag(r: Dictionary) -> String:
	if r["pos"] == "prep" or r["pos"] == "adv":
		return r["pos"] + "."
	if r["pos"] == "verb":
		return "%s %s." % [ORD[r["person"]], r["num"]]
	return "%s. %s." % [r["case"], r["num"]]


## Analyse a row of words. Returns status ok|word|incomplete|error|phrase,
## the Latin, a message, a role tag per word, and a grammar signature.
static func analyze(words: Array) -> Dictionary:
	var n := words.size()
	var roles := []
	roles.resize(n)
	roles.fill("")
	var latins := PackedStringArray()
	for w in words:
		latins.append(w["latin"])
	var res := {"status": "none", "msg": "", "roles": roles, "latin": " ".join(latins)}
	if n == 0:
		return res

	for i in n:
		if not words[i]["complete"] and words[i]["stem"] != "":
			roles[i] = "needs an ending"
	for w in words:
		if not w["complete"]:
			res["status"] = "incomplete"
			res["msg"] = w["msg"]
			return res

	if n == 1 and words[0]["readings"][0]["pos"] != "verb":
		var tags := PackedStringArray()
		for r in words[0]["readings"]:
			tags.append(reading_tag(r) if not r.has("case") else CASE_NAME[r["case"]] + " " + NUM[r["num"]])
		res["status"] = "word"
		res["msg"] = "\n".join(tags)
		var short := PackedStringArray()
		for r in words[0]["readings"]:
			short.append(reading_tag(r))
		roles[0] = " / ".join(short)
		return res

	# Every combination of possible readings (endings like -ae are ambiguous).
	var combos := [[]]
	for w in words:
		var nxt := []
		for c in combos:
			for r in w["readings"]:
				var c2: Array = c.duplicate()
				c2.append(r)
				nxt.append(c2)
		combos = nxt
		if combos.size() > 20000:
			break

	var best := {}
	var best_combo := []
	var best_score := -1
	var reasons := {}
	for c in combos:
		var e := _evaluate(c, true)
		if e["valid"]:
			if e["score"] > best_score:
				best_score = e["score"]
				best = e
				best_combo = c
		else:
			reasons[e["reason"]] = true

	if best_score >= 0:
		res["status"] = "ok"
		for i in n:
			roles[i] = _role(best_combo[i])
		return res

	res["status"] = "error"
	var verb_words := PackedStringArray()
	for w in words:
		if w["readings"][0]["pos"] == "verb":
			verb_words.append(w["latin"])
	if verb_words.is_empty():
		res["status"] = "phrase"
		res["msg"] = "No verb yet — take a round verb stem from the tray."
		return res
	if verb_words.size() > 1:
		res["msg"] = "One verb per sentence — you have %s." % " and ".join(verb_words)
		return res
	for c in combos:
		var e2 := _evaluate(c, false)
		if e2["valid"] and e2["subj"] >= 0:
			var sw: Dictionary = words[e2["subj"]]
			var sr: Dictionary = c[e2["subj"]]
			var vw: Dictionary = words[e2["verb"]]
			var vr: Dictionary = c[e2["verb"]]
			if vr["person"] != 3:
				res["msg"] = "%s is a nominative subject, but %s is %s person. A noun subject needs a 3rd-person ending (-t or -unt)." % [
						sw["latin"], vw["latin"], ORD[vr["person"]]]
			else:
				res["msg"] = "%s is %s but %s is %s — subject and verb must match." % [
						sw["latin"], NUM[sr["num"]], vw["latin"], NUM[vr["num"]]]
			return res
	if reasons.has("two_subj"):
		res["msg"] = "Two nominatives! Give one an accusative ending (-am, -um, -as, -os) to make it the object."
	elif reasons.has("two_obj"):
		res["msg"] = "Two accusatives — only one noun can be the direct object here."
	elif reasons.has("gen"):
		res["msg"] = "A genitive needs a noun right next to it to belong to."
	elif reasons.has("two_dat"):
		res["msg"] = "Too many datives — use one."
	else:
		res["msg"] = "These words don't fit together yet."
	return res


static func _evaluate(combo: Array, strict: bool) -> Dictionary:
	var e := {"valid": false, "reason": "", "score": 0, "subj": -1, "obj": -1, "dat": -1, "verb": -1, "gens": {}}
	var noms := []
	var accs := []
	var dats := []
	var gens := []
	var verbs := []
	for i in combo.size():
		var r: Dictionary = combo[i]
		if r["pos"] == "verb":
			verbs.append(i)
		elif r["pos"] != "noun":
			continue
		else:
			match r["case"]:
				"nom": noms.append(i)
				"acc": accs.append(i)
				"dat": dats.append(i)
				"gen": gens.append(i)
	if verbs.size() != 1:
		e["reason"] = "verbs"
		return e
	if noms.size() > 1:
		e["reason"] = "two_subj"
		return e
	if accs.size() > 1:
		e["reason"] = "two_obj"
		return e
	if dats.size() > 1:
		e["reason"] = "two_dat"
		return e
	var v: Dictionary = combo[verbs[0]]
	if noms.size() == 1 and strict:
		var nr: Dictionary = combo[noms[0]]
		if v["person"] != 3 or v["num"] != nr["num"]:
			e["reason"] = "agree"
			return e
	for g in gens:
		var h := -1
		for cand in [g - 1, g + 1]:
			if cand >= 0 and cand < combo.size():
				var cr: Dictionary = combo[cand]
				if cr["pos"] == "noun" and cr["case"] != "gen":
					h = cand
					break
		if h == -1:
			e["reason"] = "gen"
			return e
		e["gens"][g] = h
	e["valid"] = true
	e["verb"] = verbs[0]
	e["subj"] = noms[0] if noms.size() > 0 else -1
	e["obj"] = accs[0] if accs.size() > 0 else -1
	e["dat"] = dats[0] if dats.size() > 0 else -1
	e["score"] = 3 * noms.size() + 3 * accs.size() + dats.size() + gens.size()
	return e


static func _role(r: Dictionary) -> String:
	if not r.has("case") and r["pos"] != "verb":
		return reading_tag(r)
	if r["pos"] == "verb":
		return "verb · " + reading_tag(r)
	var role: String = {"nom": "subject", "acc": "object", "dat": "indirect obj.", "gen": "possessor"}[r["case"]]
	return role + " · " + reading_tag(r)


static func describe_stem(key: String) -> String:
	var s: Dictionary = STEMS[key]
	if s["pos"] != "verb" and s["pos"] != "noun" and s["pos"] != "adj":
		return s["dict"]
	if s["pos"] == "verb":
		return "%s\n%s" % [s["dict"], VCLASS_NAME[s["vclass"]]]
	return "%s-     %s\n%s declension noun" % [key, s["dict"], ORD[s["decl"]]]


static func describe_ending(cat: String, key: String) -> String:
	if cat == "verb":
		var e: Dictionary = VERB_ENDINGS[key]
		var t := "-%s     verb ending\n%s person %s" % [key, ORD[e["person"]], NUM[e["num"]]]
		if key in CAPS:
			return t + "\nbig enough to cap an ā-stem's a"
		return t + "\ninsert tab: %s (hides inside a vowel knob)" % e["ins"]
	var parts := PackedStringArray()
	for r in NOUN_ENDINGS[cat][key]:
		parts.append("%s %s" % [CASE_NAME[r[0]], NUM[r[1]]])
	return "-%s     %s noun ending\n%s" % [key, DRAWER_NAME[cat], "\n".join(parts)]
