# Star Fox Adventures - Xbox 360 port

## Objetivo

Este diretório contém o alvo Xbox 360 separado do build de decompilação/matching do GameCube.

O código original continua sendo a fonte da lógica, estruturas e comportamento do jogo. A camada Xbox 360 será integrada em etapas pequenas, sempre preservando o máximo possível das interfaces originais.

A etapa atual é um bootstrap independente. Ela ainda não compila nenhum módulo de gameplay de Star Fox Adventures.

## Baseline

Repositório upstream: zcanann/SFA-Decomp.

Baseline usada para iniciar o port: `13491b1880c8326f4acba4ca35d7e891ae78a806`.

Branch local: `xbox360-port`.

Versão principal da decompilação: GSAE01, NTSC-U 1.0.

## Estrutura do código original

O projeto é majoritariamente C, com pequenas partes em C++, arquivos `.cp` e assembly PowerPC.

O build original usa CodeWarrior/MWCC para Gekko, Ninja, DTK e objdiff. Ele existe para reconstrução e matching do binário de GameCube e não será usado como build do Xbox 360.

Os principais grupos em `src/` são `dlls`, `main`, `dolphin`, `musyx`, `MSL_C`, `Runtime.PPCEABI.H`, `track` e `xref`.

As dependências de plataforma mais importantes são Nintendo Dolphin SDK, GX, VI, PAD, DVD, CARD, OS, AI/DSP e MusyX.

## Mapa inicial de dependências

Uma varredura estática dos fontes encontrou forte acoplamento direto à plataforma em `src/main` e nas bibliotecas de suporte. Em `src/dlls`, uma parte relevante não chama APIs Dolphin/MusyX diretamente e é a principal candidata a reaproveitamento progressivo.

O ponto de entrada original está em `src/main/gameloop.c`. O fluxo principal é `main -> init -> gameLoop`.

`init()` inicializa OS, DVD, VI, PAD, vídeo, memória, texto, controles, áudio, arquivos, recursos, objetos e DLLs do jogo.

`gameLoop()` sincroniza frame, atualiza controles e gameplay, executa áudio, renderização, interface, legendas, carregamentos e liberações adiadas.

`src/main/pi_videoinit.c`, `shader_dolphin.c` e `rcp_dolphin.c` são fortemente ligados ao GX/Gekko. Eles serão substituídos por um backend Direct3D 9 para Xbox 360.

`src/main/pad.c` depende de PAD. O equivalente Xbox 360 usará XInput mantendo uma interface de estado de controle compatível com os consumidores do jogo.

`src/main/fileio.c` e outros carregadores dependem de DVD/CARD. O backend Xbox 360 usará caminhos do título e APIs de arquivo disponíveis no XDK.

`src/main/audio.c` e `src/musyx` dependem de AI/DSP/MusyX. O áudio será uma etapa posterior, depois que vídeo, input, tempo, arquivos e recursos básicos funcionarem no hardware.

O projeto original não depende de SDL, OpenGL ou DirectX moderno como camada principal. As APIs incompatíveis relevantes são as APIs nativas do GameCube e partes específicas do PowerPC Gekko.

## Fronteiras de plataforma previstas

As fronteiras serão introduzidas conforme cada sistema for integrado: gráficos, input, temporização, filesystem, threads, áudio, armazenamento, rede e recursos.

A interface será mantida próxima do uso original quando isso reduzir mudanças nos módulos de gameplay.

## Etapas de validação

1. Bootstrap: inicialização, loop e tela sólida por Direct3D 9.
2. Shader mínimo: triângulo ou quad com vertex/pixel shader compilado para Xbox 360.
3. Input: leitura do controle Xbox 360 e diagnóstico visual de botões/eixos.
4. Tempo: contador monotônico, delta time e sincronização de frame.
5. Filesystem: abrir, ler e validar um arquivo conhecido ao lado do XEX.
6. Recursos: carregar uma textura/recurso simples do disco e desenhá-lo.
7. Núcleo do jogo: começar a importar código independente de plataforma e resolver dependências uma a uma.
8. Renderização SFA: traduzir os estados GX/TEV necessários para o backend Xbox 360.
9. Áudio, armazenamento, threads e subsistemas restantes.
10. Distribuição: pasta limpa com `default.xex` e somente os recursos necessários.

Cada etapa só é considerada concluída depois de funcionar em um Xbox 360 real. Xenia pode ser usado como smoke test, mas não substitui a validação em hardware.

O ciclo de trabalho de cada etapa é editar, compilar, gerar XEX, transferir, executar, observar diagnóstico, corrigir e repetir.

## Etapa atual

`src/main.cpp` cria um dispositivo Direct3D 9 em 1280x720, configura depth buffer, limpa a tela com uma cor fixa e apresenta frames continuamente.

As mensagens `SFA-X360 bootstrap: start`, `graphics init failed` e `graphics ready` permitem localizar a falha de inicialização quando houver canal de debug disponível.

O critério de conclusão desta etapa é o Xbox 360 real iniciar `default.xex` e permanecer exibindo a tela sólida sem retornar ao dashboard.

## Toolchain

O pipeline foi preparado para XDK 2.0.21256.3.

O script usa `%XEDK%\bin\win32\cl.exe`, `link.exe` e `imagexex.exe`, headers em `%XEDK%\include\xbox` e bibliotecas em `%XEDK%\lib\xbox`.

Depois do ImageXex, o XexTool transforma a cópia de distribuição em formato adequado ao teste em RGH e remove restrições de execução.

Build esperado:

```powershell
$env:XEDK = "C:\caminho\para\Microsoft Xbox 360 SDK"
powershell -ExecutionPolicy Bypass -File .\ports\xbox360\build.ps1 -XexTool "C:\caminho\xextool.exe"
```

Saídas esperadas:

```text
ports\xbox360\build\SFA-X360-devkit.xex
ports\xbox360\dist\default.xex
```

## Estado do PC em 30/09/2026

O XexTool v6.3 está disponível localmente.

O XDK não está instalado nem registrado no Windows atual. `XEDK` está vazio; `cl.exe`, `link.exe`, `imagexex.exe`, `xboxkrnl.lib`, `xapilib.lib`, `d3d9.lib`, `xbcp.exe`, `xbreboot.exe` e `xbdm.dll` do XDK não foram encontrados.

O MSBuild 4.0 existe, porém Visual Studio 2010 e os targets MSBuild `Xbox 360` não estão presentes.

Por isso a etapa atual ainda não pode produzir um novo `default.xex` neste PC. O script falha antes da compilação com uma mensagem específica enquanto o XDK estiver ausente.

Nenhuma parte da lógica original de Star Fox Adventures foi alterada nesta etapa.
