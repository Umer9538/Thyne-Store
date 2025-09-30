package main
import (
  "fmt"
  "golang.org/x/crypto/bcrypt"
)
func main(){
  pwds := []string{"Admin@123","Password@123"}
  for _, p := range pwds {
    h, _ := bcrypt.GenerateFromPassword([]byte(p), 12)
    fmt.Printf("%s\t%s\n", p, string(h))
  }
}
