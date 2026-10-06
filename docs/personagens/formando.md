# Formando

Protagonista da cutscene da colação de grau.

## Visual

- Beca preta em cone, com pregas na frente e ombros arredondados; balança ao andar.
- Mangas em sino com punho na cor da faixa; mãos com polegar.
- Faixa colorida com borda dourada e franja, gola branca.
- Rosto com olhos de íris colorida, sobrancelhas, nariz, bochechas rosadas e sorriso.
- Cabelo com cor sorteada; alguns têm cabelo comprido atrás.
- Capelo com copa, placa quadrada levemente torta, botão e borla dourada pendurada.
- Calça escura e sapatos pretos polidos.
- Braços com pivô no ombro para animar aceno, aperto de mão e comemoração.
- Tecido com o shader `plush.gdshader` (aspecto de veludo com brilho nas bordas).

## Plateia

Sentada de frente para o palco, aplaudindo, com um leve balanço entre as pessoas.
O som da colação é só de ambiente: passos na madeira, palmas, vivas e assobios;
depois que a câmera foca no Facefinho, as palmas ficam abafadas e entra um zumbido
grave. Não há estática na cutscene, só o grito do susto final.

## Na cutscene

1. Sobe os degraus de madeira pelo tapete vermelho.
2. Caminha até a mesa da banca.
3. Recebe o canudo do reitor (câmera lenta no contato).
4. Vira para a plateia e ergue o diploma.

## Arquivos

Modelo em `scripts/graduate.gd` (o mesmo para plateia, reitor e banca);
`scripts/game.gd` cria cada um em `_make_graduate`.
