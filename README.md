# Spreadsheet

Esse projeto é um exercício sugerido pelo [Casssiano](https://github.com/cassiano), que consiste na implementação em uma planilha de cálculos.

Por ora, o projeto está em fase alpha, e não trata quase nenhum caso de excessão.

[![Obligatory gif](https://asciinema.org/a/4677dtu9ippkmzgttr85vnj22.png)](https://asciinema.org/a/4677dtu9ippkmzgttr85vnj22)

## Implementação

Foram utilizados vários conceitos descritos no paper [Deprecating the Observer Pattern](http://infoscience.epfl.ch/record/148043/files/DeprecatingObserversTR2010.pdf) para implementação, já que cada célula representa um `Signal` descrito no paper.

Para o parsing das fórmulas da planilha, foi desenvolvido um simples parser com o [Treetop](http://treetop.rubyforge.org/).

A UI (ainda bastante simplista) foi produzida com a ajuda da biblioteca [Curses](https://en.wikipedia.org/wiki/Curses_(programming_library)).

## Demo

Para rodar o demo, primeiro instale as dependências com:

    $ bundle install

E depois execute

    $ ./demo.rb
