# @file home/modules/vscode.nix
# @description VS Code configuration with extensions and settings
# @update-policy Update when new extensions or language support needed
# @note Migrated from existing VS Code setup on 2025-12-15

{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.vscode;
in

{
  options.programs.vscode = {
    enable = mkEnableOption "Visual Studio Code with extensions";
    
    languageSupport = {
      python = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Python language support";
      };
      
      elixir = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Elixir language support";
      };
      
      go = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Go language support";
      };
      
      csharp = mkOption {
        type = types.bool;
        default = true;
        description = "Enable C# / .NET language support";
      };
      
      r = mkOption {
        type = types.bool;
        default = true;
        description = "Enable R language support";
      };
      
      nix = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Nix language support";
      };
      
      latex = mkOption {
        type = types.bool;
        default = true;
        description = "Enable LaTeX support";
      };
      
      terraform = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Terraform/HCL support";
      };
    };
    
    features = {
      copilot = mkOption {
        type = types.bool;
        default = true;
        description = "Enable GitHub Copilot (requires subscription)";
      };
      
      docker = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Docker support";
      };
      
      markdown = mkOption {
        type = types.bool;
        default = true;
        description = "Enable enhanced Markdown support";
      };
    };
    
    customSettings = mkOption {
      type = types.attrs;
      default = {};
      example = {
        "editor.fontSize" = 14;
        "editor.fontFamily" = "'JetBrains Mono', 'Fira Code', monospace";
      };
      description = "Custom VS Code settings (settings.json)";
    };
  };
  
  config = mkIf cfg.enable {
    programs.vscode = {
      enable = true;
      package = pkgs.vscode;
      
      # Extensions based on your current setup
      extensions = with pkgs.vscode-extensions; [
        # Core productivity
        ${optionalString cfg.features.copilot ''
        github.copilot
        github.copilot-chat
        ''}
        
        # Python
        ${optionalString cfg.languageSupport.python ''
        ms-python.python
        ms-python.vscode-pylance
        ms-python.debugpy
        ''}
        
        # Go
        ${optionalString cfg.languageSupport.go ''
        golang.go
        ''}
        
        # Nix
        ${optionalString cfg.languageSupport.nix ''
        jnoortheen.nix-ide
        ''}
        
        # Docker
        ${optionalString cfg.features.docker ''
        ms-azuretools.vscode-docker
        ''}
        
        # Markdown
        ${optionalString cfg.features.markdown ''
        bierner.markdown-mermaid
        ''}
        
        # Utilities
        mechatroner.rainbow-csv
        
      ] ++ (with pkgs.vscode-marketplace; [
        # Elixir (from marketplace)
        ${optionalString cfg.languageSupport.elixir ''
        {
          name = "elixir-ls";
          publisher = "jakebecker";
          version = "0.30.0";
          sha256 = "sha256-PLACEHOLDER"; # Will be auto-downloaded
        }
        {
          name = "elixir-test";
          publisher = "samuel-pordeus";
          version = "1.8.1";
          sha256 = "sha256-PLACEHOLDER";
        }
        {
          name = "vscode-eex-format";
          publisher = "royalmist";
          version = "0.5.0";
          sha256 = "sha256-PLACEHOLDER";
        }
        ''}
        
        # C# / .NET (from marketplace)
        ${optionalString cfg.languageSupport.csharp ''
        {
          name = "csharp";
          publisher = "ms-dotnettools";
          version = "2.110.4";
          sha256 = "sha256-PLACEHOLDER";
        }
        {
          name = "csdevkit";
          publisher = "ms-dotnettools";
          version = "1.90.2";
          sha256 = "sha256-PLACEHOLDER";
        }
        {
          name = "csharpextensions";
          publisher = "kreativ-software";
          version = "1.7.3";
          sha256 = "sha256-PLACEHOLDER";
        }
        ''}
        
        # R language (from marketplace)
        ${optionalString cfg.languageSupport.r ''
        {
          name = "r";
          publisher = "reditorsupport";
          version = "2.8.6";
          sha256 = "sha256-PLACEHOLDER";
        }
        {
          name = "r-syntax";
          publisher = "reditorsupport";
          version = "0.1.3";
          sha256 = "sha256-PLACEHOLDER";
        }
        ''}
        
        # LaTeX (from marketplace)
        ${optionalString cfg.languageSupport.latex ''
        {
          name = "latex-workshop";
          publisher = "james-yu";
          version = "10.12.0";
          sha256 = "sha256-PLACEHOLDER";
        }
        {
          name = "latex-utilities";
          publisher = "tecosaur";
          version = "0.4.14";
          sha256 = "sha256-PLACEHOLDER";
        }
        {
          name = "latex-citations";
          publisher = "maltehei";
          version = "1.4.0";
          sha256 = "sha256-PLACEHOLDER";
        }
        ''}
        
        # Terraform/HCL (from marketplace)
        ${optionalString cfg.languageSupport.terraform ''
        {
          name = "terraform";
          publisher = "hashicorp";
          version = "2.37.6";
          sha256 = "sha256-PLACEHOLDER";
        }
        {
          name = "hcl";
          publisher = "hashicorp";
          version = "0.6.0";
          sha256 = "sha256-PLACEHOLDER";
        }
        ''}
        
        # Development tools
        {
          name = "makefile-tools";
          publisher = "ms-vscode";
          version = "0.12.17";
          sha256 = "sha256-PLACEHOLDER";
        }
        {
          name = "vscode-python-envs";
          publisher = "ms-python";
          version = "1.14.0";
          sha256 = "sha256-PLACEHOLDER";
        }
        {
          name = "python-path";
          publisher = "mgesbert";
          version = "0.0.14";
          sha256 = "sha256-PLACEHOLDER";
        }
      ]);
      
      # User settings
      userSettings = mkMerge [
        {
          # Editor
          "editor.formatOnSave" = true;
          "editor.tabSize" = 2;
          "editor.insertSpaces" = true;
          "editor.rulers" = [ 80 120 ];
          "editor.minimap.enabled" = false;
          "editor.bracketPairColorization.enabled" = true;
          "editor.guides.bracketPairs" = "active";
          
          # Files
          "files.autoSave" = "afterDelay";
          "files.autoSaveDelay" = 1000;
          "files.trimTrailingWhitespace" = true;
          "files.insertFinalNewline" = true;
          
          # Terminal
          "terminal.integrated.fontSize" = 12;
          "terminal.integrated.scrollback" = 10000;
          
          # Git
          "git.autofetch" = true;
          "git.confirmSync" = false;
          
          # Workbench
          "workbench.startupEditor" = "newUntitledFile";
          "workbench.editor.enablePreview" = false;
          
          # Telemetry
          "telemetry.telemetryLevel" = "off";
        }
        
        # Python-specific settings
        (mkIf cfg.languageSupport.python {
          "python.defaultInterpreterPath" = "python3";
          "python.linting.enabled" = true;
          "python.linting.pylintEnabled" = false;
          "python.linting.flake8Enabled" = true;
          "python.formatting.provider" = "black";
          "[python]" = {
            "editor.formatOnSave" = true;
            "editor.rulers" = [ 88 ];
          };
        })
        
        # Elixir-specific settings
        (mkIf cfg.languageSupport.elixir {
          "elixirLS.dialyzerEnabled" = true;
          "elixirLS.fetchDeps" = false;
          "[elixir]" = {
            "editor.formatOnSave" = true;
            "editor.insertSpaces" = true;
            "editor.tabSize" = 2;
          };
        })
        
        # Go-specific settings
        (mkIf cfg.languageSupport.go {
          "go.toolsManagement.autoUpdate" = true;
          "[go]" = {
            "editor.formatOnSave" = true;
            "editor.codeActionsOnSave" = {
              "source.organizeImports" = "explicit";
            };
          };
        })
        
        # Nix-specific settings
        (mkIf cfg.languageSupport.nix {
          "nix.enableLanguageServer" = true;
          "nix.serverPath" = "${pkgs.nil}/bin/nil";
          "[nix]" = {
            "editor.formatOnSave" = true;
            "editor.tabSize" = 2;
          };
        })
        
        # LaTeX-specific settings
        (mkIf cfg.languageSupport.latex {
          "latex-workshop.latex.autoBuild.run" = "onFileChange";
          "latex-workshop.view.pdf.viewer" = "tab";
        })
        
        # Copilot settings
        (mkIf cfg.features.copilot {
          "github.copilot.enable" = {
            "*" = true;
            "yaml" = false;
            "plaintext" = false;
          };
        })
        
        # User custom settings (override defaults)
        cfg.customSettings
      ];
    };
    
    # Install language servers and formatters
    home.packages = with pkgs; [
      # Python tools
      ${optionalString cfg.languageSupport.python ''
      python3Packages.black
      python3Packages.flake8
      python3Packages.pylint
      ''}
      
      # Go tools
      ${optionalString cfg.languageSupport.go ''
      go
      gopls
      ''}
      
      # Nix tools
      ${optionalString cfg.languageSupport.nix ''
      nil
      nixpkgs-fmt
      ''}
      
      # Elixir tools (handled by asdf in elixir.nix)
      
      # C# tools (handled by dotnet SDK in development.nix)
      
      # R tools
      ${optionalString cfg.languageSupport.r ''
      R
      rPackages.languageserver
      ''}
    ];
    
    # Shell aliases
    programs.bash.shellAliases = mkIf config.programs.bash.enable {
      code = "code";
      vsc = "code .";
    };
    
    programs.zsh.shellAliases = mkIf config.programs.zsh.enable {
      code = "code";
      vsc = "code .";
    };
    
    # Activation message
    home.activation.vscodeInfo = lib.hm.dag.entryAfter ["writeBoundary"] ''
      echo "[vscode] VS Code configured with extensions"
      echo "[vscode] Launch: code or vsc (opens current directory)"
      ${optionalString cfg.features.copilot ''
        echo "[vscode] GitHub Copilot enabled (sign in required)"
      ''}
    '';
  };
}
