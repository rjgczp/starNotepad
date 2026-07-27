package starNote

const (
	TagIDNewcomer           uint = 1
	TagIDNoteMaster         uint = 2
	TagIDStarTraveler       uint = 3
	TagIDLifeRecorder       uint = 4
	TagIDInspirationCatcher uint = 5
	TagIDLiteraryPoet       uint = 6
	TagIDMinimalist         uint = 7
	TagIDSelfDiscipline     uint = 8
	TagIDEfficiencyExpert   uint = 9
	TagIDVeteranUser        uint = 10
	TagIDCreativePioneer    uint = 11
	TagIDActiveMember       uint = 12
	TagIDFounder            uint = 13
	TagIDTimeCollector      uint = 14
	TagIDGoldCollector      uint = 15
	TagIDDreamer            uint = 16
)

// BuiltinTagMeta 定义系统内置标签元数据。
type BuiltinTagMeta struct {
	ID    uint
	Name  string
	Color string
}

var BuiltinTagList = []BuiltinTagMeta{
	{ID: 1, Name: "新人报道", Color: "#722ED1"},
	{ID: 2, Name: "记事达人", Color: "#1890FF"},
	{ID: 3, Name: "星空旅者", Color: "#2F54EB"},
	{ID: 4, Name: "生活记录者", Color: "#52C41A"},
	{ID: 5, Name: "灵感捕手", Color: "#EB2F96"},
	{ID: 6, Name: "文学诗客", Color: "#D48806"},
	{ID: 7, Name: "极简主义", Color: "#595959"},
	{ID: 8, Name: "自律模范", Color: "#13C2C2"},
	{ID: 9, Name: "效率专家", Color: "#22075E"},
	{ID: 10, Name: "元老用户", Color: "#820014"},
	{ID: 11, Name: "创意先锋", Color: "#FA541C"},
	{ID: 12, Name: "活跃分子", Color: "#F5222D"},
	{ID: 13, Name: "创始人", Color: "#391085"},
	{ID: 14, Name: "拾光者", Color: "#A0D911"},
	{ID: 15, Name: "金牌收藏家", Color: "#BF9000"},
	{ID: 16, Name: "梦想家", Color: "#F759AB"},
}

var BuiltinTagNameByID = map[uint]string{
	1:  "新人报道",
	2:  "记事达人",
	3:  "星空旅者",
	4:  "生活记录者",
	5:  "灵感捕手",
	6:  "文学诗客",
	7:  "极简主义",
	8:  "自律模范",
	9:  "效率专家",
	10: "元老用户",
	11: "创意先锋",
	12: "活跃分子",
	13: "创始人",
	14: "拾光者",
	15: "金牌收藏家",
	16: "梦想家",
}

var BuiltinTagByID = map[uint]BuiltinTagMeta{
	1:  {ID: 1, Name: "新人报道", Color: "#722ED1"},
	2:  {ID: 2, Name: "记事达人", Color: "#1890FF"},
	3:  {ID: 3, Name: "星空旅者", Color: "#2F54EB"},
	4:  {ID: 4, Name: "生活记录者", Color: "#52C41A"},
	5:  {ID: 5, Name: "灵感捕手", Color: "#EB2F96"},
	6:  {ID: 6, Name: "文学诗客", Color: "#D48806"},
	7:  {ID: 7, Name: "极简主义", Color: "#595959"},
	8:  {ID: 8, Name: "自律模范", Color: "#13C2C2"},
	9:  {ID: 9, Name: "效率专家", Color: "#22075E"},
	10: {ID: 10, Name: "元老用户", Color: "#820014"},
	11: {ID: 11, Name: "创意先锋", Color: "#FA541C"},
	12: {ID: 12, Name: "活跃分子", Color: "#F5222D"},
	13: {ID: 13, Name: "创始人", Color: "#391085"},
	14: {ID: 14, Name: "拾光者", Color: "#A0D911"},
	15: {ID: 15, Name: "金牌收藏家", Color: "#BF9000"},
	16: {ID: 16, Name: "梦想家", Color: "#F759AB"},
}

func GetBuiltinTagNameByID(id uint) (string, bool) {
	name, ok := BuiltinTagNameByID[id]
	return name, ok
}

func GetBuiltinTagByID(id uint) (BuiltinTagMeta, bool) {
	tag, ok := BuiltinTagByID[id]
	return tag, ok
}
