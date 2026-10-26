# Estudante (jogador)

Aluno da Uni-FACEF que esqueceu os documentos da faculdade e volta à noite,
com o prédio vazio, para recuperar os oito.

## Início

Começa do lado de fora, no pátio em frente à fachada, com o portão fechado
atrás dele. Ao entrar, vê a fantasia do Facefinho pendurada nos achados e
perdidos, com um bilhete de aviso preso no peito. Os documentos só podem ser
pegos depois de ler o bilhete, e é a leitura que desperta o mascote.

## Visual

Não tem corpo visível: o jogo é em primeira pessoa. Só aparecem a lanterna e o
caderno que ele segura ao pegar um documento.

## Controles

| Tecla | Ação |
| --- | --- |
| WASD | Andar |
| Mouse | Olhar |
| Shift | Correr |
| Ctrl (segurar) | Agachar: anda devagar, faz pouco barulho e fica mais fácil de esconder atrás dos móveis |
| F | Lanterna |
| E | Pegar documento, ou entrar e sair de um armário |
| Espaço | Prender a respiração dentro do armário, quando ele está perto |
| Esc | Soltar o mouse |
| F3 | Painel de debug |

## Recursos

- Lanterna com bateria; recarrega quando desligada.
- Agachado, o Facefinho só ouve os passos a 2–3 m, contra 7–10 m andando e 16–22 m correndo. Não dá para correr agachado, e só se levanta quando há espaço acima.
- Ao pegar um documento, o caderno vem até a câmera e abre.
- Armários nas salas: E entra, a porta fecha, e o mascote não alcança enquanto se está dentro. E sai.
- Se ele chega perto do armário, segure Espaço para prender a respiração. Soltar cedo demais, ou ficar sem ar, faz ele abrir a porta e puxar você para fora.

## Arquivos

- `scripts/player.gd`
- `scripts/page.gd` (animação do caderno)
