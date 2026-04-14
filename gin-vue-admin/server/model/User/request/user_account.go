package request

type Login struct {
	Username  string `json:"username"`  // 用户名/ID
	Password  string `json:"password"`  // 密码
}