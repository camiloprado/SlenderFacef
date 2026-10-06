# Facefinho

Mascote da Uni-FACEF e perseguidor do jogo.

## Conceito

A fantasia real do mascote, esquecida no cabide dos achados e perdidos da
entrada. O corpo inteiro é a pilha de três livros azuis de pelúcia; não existe
cabeça separada. A fantasia está vazia até alguém tirar o bilhete preso nela.

Fotos de referência: `docs/arte/facefinho/referencias/`.

## Visual

| Parte | Descrição |
| --- | --- |
| Altura | Cerca de 2 m; olhos a 1,82 m |
| Corpo | Três livros azuis felpudos empilhados, levemente desalinhados, de 0,6 m a 2 m |
| Páginas | Brancas, aparecendo nas duas laterais e atrás de cada livro, com linhas de folhas |
| Rosto | No livro de cima: olhos grandes brancos encostados, pupilas pretas, sobrancelhas pretas grossas |
| Boca | Sorriso aberto em "D" com dentes brancos e língua vermelha |
| Braços | Mangas pretas saindo das laterais, luvas brancas de desenho animado |
| Pernas | Calça preta (as pernas de quem veste) |
| Pés | Tênis grandes azuis com bico e sola brancos |
| Material | `shaders/plush.gdshader`; livros gerados como caixas arredondadas (superquádricas) |

## Poses

- **Pendurada:** livros tortos, mangas e calças murchas, tênis caídos com a ponta
  para baixo, balançando no cabide.
- **Em pé:** braços abertos como nas fotos.
- **Andando:** passo travado de boneco; quando ele para, a pose congela no meio do passo.

## Comportamento

- Fica pendurado e inativo até o jogador ler o bilhete de aviso.
- Quando o bilhete é guardado, a fantasia some do cabide e ele começa no corredor central do Bloco C, no fundo da escola.
- Congela quando o jogador olha para ele, até 28 m.
- Faz barulho: passos abafados de pelúcia com rangido de tênis (ouvidos até 30 m),
  respiração rouca em loop (até 13 m) e um vulto ao teletransportar.
- Quando está perto e fora da visão, a tela ganha uma borda vermelha que pulsa com
  o coração, o batimento acelera e um zumbido agudo sobe.
- A estática só sobe quando ele está na visão do jogador, mais forte de perto.
- Cada documento acadêmico muda uma regra dele.
- **Estágio obrigatório:** ele passa a seguir o jogador de perto, sempre atrás,
  mantendo uns 4 m de distância (menos conforme a agressividade sobe). Não mata
  enquanto o jogador se move. Se o jogador ficar parado mais de 3 s, ele avança
  para pegar. Se aparecer na frente do jogador, logo volta para trás dele.

## Na colação

Fica imóvel no canto do fundo, perto da saída. No final avança contra a câmera
com a boca escancarada.

## Arquivos

- `scripts/costume.gd`: modelo, poses e passo.
- `scripts/slender.gd`: perseguição.
- `models/unifacef_book_mascot.glb` e `models/unifacef_book_mascot_backup.glb`:
  modelos antigos da pilha de livros, não usados mais pela fantasia.
