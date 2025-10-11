# @file home/modules/shell.nix
# @description DevOps-optimized zsh configuration with Oh My Zsh and Powerlevel10k
# @update-policy Update when shell configuration, plugins, or DevOps tooling changes

{ config, pkgs, ... }:

{
  # Enable zsh via Home-Manager
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    
    # Oh My Zsh configuration with DevOps plugins
    oh-my-zsh = {
      enable = true;
      theme = "powerlevel10k/powerlevel10k";
      plugins = [
        "git"                      # Git aliases and completion
        "docker"                   # Docker completion
        "kubectl"                  # Kubernetes completion
        "terraform"                # Terraform completion
        "aws"                      # AWS CLI completion
        "zsh-autosuggestions"      # Command suggestions from history
        "zsh-syntax-highlighting"  # Syntax validation as you type
      ];
    };
    
    # Custom .zshrc content
    initExtra = ''
      # Powerlevel10k instant prompt (MUST be first for performance)
      if [[ -r "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
        source "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh"
      fi
      
      # ===== Autosuggestions Performance Optimization =====
      # Async mode prevents typing lag during command execution
      ZSH_AUTOSUGGEST_USE_ASYNC=true
      
      # Ignore very long commands (e.g., huge JSON payloads)
      ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=50
      
      # Use both history and completion for suggestions
      ZSH_AUTOSUGGEST_STRATEGY=(history completion)
      
      # ===== History Configuration for DevOps =====
      # Large history size for complex command recall
      HISTSIZE=50000
      SAVEHIST=50000
      
      # Deduplicate commands in history
      setopt HIST_IGNORE_DUPS           # Don't record duplicate consecutive commands
      setopt HIST_IGNORE_ALL_DUPS       # Remove older duplicates when adding new
      
      # Privacy: Ignore commands starting with space
      # Usage: " aws configure" won't be saved to history
      setopt HIST_IGNORE_SPACE
      
      # Load Powerlevel10k configuration
      [[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh
    '';
    
    # Profile additions (.zprofile equivalent)
    profileExtra = ''
      # User-local CLI tools (e.g., pipx, local bins)
      export PATH="$PATH:$HOME/.local/bin"
    '';
  };
  
  # fzf integration for advanced history search
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    # Ctrl+R for fuzzy history search
    # Ctrl+T for fuzzy file search
    # Alt+C for fuzzy directory navigation
  };
  
  # Install zsh plugins and theme via nixpkgs
  home.packages = with pkgs; [
    # Oh My Zsh plugins (declarative installation)
    zsh-autosuggestions
    zsh-syntax-highlighting
    
    # Powerlevel10k theme
    zsh-powerlevel10k
    
    # fzf for advanced fuzzy search
    fzf
  ];
    zsh-syntax-highlighting
    
    # Powerlevel10k theme
    zsh-powerlevel10k
  ];
  
  # Powerlevel10k configuration file
  home.file.".p10k.zsh".text = ''
    # @file ~/.p10k.zsh
    # @description Powerlevel10k prompt configuration for DevOps workflows
    # @update-policy Regenerate via 'p10k configure' or edit manually
    
    # Instant prompt mode (critical for performance)
    typeset -g POWERLEVEL9K_INSTANT_PROMPT=verbose
    
    # ===== Right Prompt: Minimal DevOps Info =====
    typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(
      status                    # Exit code of last command
      command_execution_time    # How long command took
      background_jobs           # Background job indicator
      direnv                    # direnv status
      kubecontext               # Current kubectl context
      terraform                 # Terraform workspace
      aws                       # AWS profile
      context                   # User@host (when relevant)
      time                      # Current time
    )
    
    # ===== Left Prompt: Essential Navigation =====
    typeset -g POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(
      os_icon                   # OS indicator
      dir                       # Current directory
      vcs                       # Git status
      newline                   # Line break
      prompt_char               # Prompt symbol
    )
    
    # ===== Performance Optimizations =====
    # Skip git status in large repos (faster prompt)
    typeset -g POWERLEVEL9K_VCS_MAX_INDEX_SIZE_DIRTY=-1
    
    # Transient prompt (clean up old prompts)
    typeset -g POWERLEVEL9K_TRANSIENT_PROMPT=always
    
    # ===== Visual Style =====
    typeset -g POWERLEVEL9K_MODE='nerdfont-complete'
    typeset -g POWERLEVEL9K_ICON_PADDING=moderate
    
    # ===== Kubernetes Context Styling =====
    # Show namespace in parentheses
    typeset -g POWERLEVEL9K_KUBECONTEXT_SHOW_DEFAULT_NAMESPACE=true
    
    # Color-code production contexts (red = danger)
    typeset -g POWERLEVEL9K_KUBECONTEXT_PRODUCTION_CONTENT_EXPANSION='%F{red}⎈ ''${P9K_KUBECONTEXT_NAME}%f'
    typeset -g POWERLEVEL9K_KUBECONTEXT_PRODUCTION_PATTERN='(*production*|*prod*)'
    
    # Color-code staging contexts (yellow = caution)
    typeset -g POWERLEVEL9K_KUBECONTEXT_STAGING_CONTENT_EXPANSION='%F{yellow}⎈ ''${P9K_KUBECONTEXT_NAME}%f'
    typeset -g POWERLEVEL9K_KUBECONTEXT_STAGING_PATTERN='(*staging*|*stage*)'
    
    # Default contexts (cyan = safe)
    typeset -g POWERLEVEL9K_KUBECONTEXT_DEFAULT_CONTENT_EXPANSION='%F{cyan}⎈ ''${P9K_KUBECONTEXT_NAME}%f'
    
    # ===== AWS Profile Styling =====
    typeset -g POWERLEVEL9K_AWS_SHOW_ON_COMMAND='aws|terraform|terragrunt|kubectl'
    
    # ===== Terraform Workspace Styling =====
    typeset -g POWERLEVEL9K_TERRAFORM_SHOW_DEFAULT=true
    
    # Apply configuration
    [[ ! -f ~/.p10k.zsh.zwc ]] || source ~/.p10k.zsh.zwc
  '';
  
  # AWS CLI configuration
  home.file.".aws/config".text = ''
    [default]
    region = us-east-1
    output = json
  '';
}