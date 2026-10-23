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
- Só congela quando está dentro do facho da lanterna ligada (até 24 m). Olhar no
  escuro não o para; apenas a estática sobe.
- Não teletransporta. Longe, corre. A partir de uns 7 m, anda devagar e espreita.
  Se te vê de perto, investe. Se te perde, procura o último lugar em que te
  ouviu ou viu e depois volta a rondar os corredores.
- Quando o caminho pelo corredor passa de 18 m, ele sobe nos dutos do teto.
  Para embaixo da grelha, estica os braços, abre o metal e entra. Lá dentro
  anda mais rápido do que no chão e sai numa boca ainda longe de você. O
  jogador não entra nos dutos.
- Se você está no armário e ele chega perto, ouve a respiração. Prender o ar
  esconde o som. Se o ar acaba, ou se você solta com ele na porta, ele abre
  o armário e puxa você para o susto.
- Te vê só à frente dele, e te ouve andar por perto. Correr faz barulho mais
  longe. Ficar parado some do ouvido. A porta do armário e pegar um documento
  chamam a atenção dele.
- Faz barulho: passos abafados de pelúcia com rangido de tênis (ouvidos até 30 m)
  e respiração rouca em loop (até 13 m).
- Quando está perto e fora da visão, a tela ganha uma borda vermelha que pulsa com
  o coração, o batimento acelera e um zumbido agudo sobe.
- A estática só sobe quando ele está na visão do jogador, mais forte de perto.
- Quando alcança o jogador, faz o mesmo susto do fim da colação: aparece parado
  na frente da câmera, avança com a boca escancarada, a tela treme com estática,
  luz verde e um grito, e então corta para preto e para a tela de fim.
- Cada documento acadêmico muda uma regra dele.
- **Estágio obrigatório:** ele passa a seguir o jogador de perto, sempre atrás,
  mantendo uns 4 m de distância (menos conforme a agressividade sobe). Não mata
  enquanto o jogador se move. Se o jogador ficar parado mais de 3 s, ele avança
  para pegar. Se aparecer na frente, volta para trás andando, sem sumir.
- **Relatório de estágio:** escuta mais longe e corre mais rápido quando está distante.

## Na colação

Fica imóvel no canto do fundo, perto da saída. No final avança contra a câmera
com a boca escancarada.

## Arquivos

- `scripts/costume.gd`: modelo, poses e passo.
- `scripts/slender.gd`: perseguição.
- `models/unifacef_book_mascot.glb` e `models/unifacef_book_mascot_backup.glb`:
  modelos antigos da pilha de livros, não usados mais pela fantasia.
