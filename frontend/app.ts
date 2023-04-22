async function main() {
  const response = await fetch('/api')
  const text = await response.text()
  console.log(text)
  const root = document.getElementById('root')!
  root.innerText = text
}

main()
