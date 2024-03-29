# need to setup ssh first to copy the config repository
common_minimal_packages='git make curl'
# these should be available on all large distros. check repology.org future me
common_extra_packages='htop thunderbird firefox exa neovim kitty zsh gimp keepassxc xournalpp zathura bat zathura-pdf-poppler vlc telegram-desktop  i3lock i3status dunst rofi pyright texlab'
# the names of these differ sometimes or are not available at all
manual_minimal_packages='code'
manual_extra_packages='nextcloud-client i3-wm mattermost-desktop steam-manjaro ttf-fira-code zsh-theme-powerlevel10k'
conda_path=~/.local/anaconda3
conda_link=https://repo.anaconda.com/archive/Anaconda3-2021.05-Linux-x86_64.sh
TEXLIVE_INSTALL_PREFIX=~/.local/texlive
config_url=git@github.com:LukasNickel/cfg.git

ToDo() {
    echo "
    - Install the remaining manual packages if any
    - Login to stuff (messenger, thunderbird, firefox, ...)
    - Setup conda envs
    - Test things (eg vim lsp, zsh plugins...)
"
}

install_conda() {
    echo "Searching for conda under $conda_path"
    if [ ! -d $conda_path ]; then
        echo "Conda not found. Installing anaconda using the installer from $conda_link"
        wget $conda_link -O conda_installer.sh
        bash conda_installer.sh -p $conda_path -b
        source $conda_path/bin/activate
        conda init
        source ~/.bashrc
        conda update -y anaconda
        echo "Installing mamba via conda. Dont freak out if this takes some time"
        conda install -c conda-forge --yes mamba
        mamba install -c conda-forge --yes uncertainties
        rm conda_installer.sh
    else
        echo "Anaconda is installed already, skipping this step."
    fi
}

install_texlive() {
    echo "Searching for tex under $TEXLIVE_INSTALL_PREFIX"
    if [ ! -d $TEXLIVE_INSTALL_PREFIX ]; then echo "TeXLive not found."
        read -p "Do you wish to install TeXLive now? Warning: This takes a while because there is a lot of data to download (y/N)" answer
        case ${answer:0:1} in
            y|Y|yes|Yes|Ja|ja )
                cd ~/.local
                rm -r install-tl*
                curl -L http://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz | tar xz
                env TEXLIVE_INSTALL_PREFIX=~/.local/texlive ./install-tl-*/install-tl
                source ~/.bashrc
                tlmgr option autobackup -- -1
                tlmgr option repository http://mirror.ctan.org/systems/texlive/tlnet
                tlmgr update --self --all --reinstall-forcibly-removed
                echo 'export PATH="$HOME/.local/texlive/2021/bin/x86_64-linux:$PATH"' >> ~/.bashrc
                ;;
            * )
                echo "Skipping the TeXLive installation. You can call this script again at a later stage to continue."
                ;;
        esac
    else
        echo "TeXLive is installed already, skipping the installation"
    fi

}

add_tex_themes() {
    git clone https://github.com/maxnoe/tudobeamertheme $(kpsewhich --var-value TEXMFHOME)/tex/latex/tudobeamertheme
    git clone https://github.com/maxnoe/tudothesis $(kpsewhich --var-value TEXMFHOME)/tex/latex/tudothesis
}

configure_git() {
    echo "Setting your git settings"
    echo "Whats your name?"
    read name
    git config --global user.name "$name"
    echo "Whats your email adress?"
    read mail
    git config --global user.email "$mail"
    git config --global rebase.stat true
    git config --global merge.conflictstyle diff3
    # configurable?
    git config --global core.editor "codium --wait"
}

setup_configs() {
    # details:
    # https://www.atlassian.com/git/tutorials/dotfiles
    echo ".cfg" >> .gitignore
    git clone --bare $config_url $HOME/.cfg
    function config {
       /usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME $@
    }
    mkdir -p .config-backup
    config checkout
    if [ $? = 0 ]; then
      echo "Checked out config.";
      else
        echo "Backing up pre-existing dot files.";
        config checkout 2>&1 | egrep "\s+\." | awk {'print $1'} | xargs -I{} mv {} .config-backup/{}
    fi;
    config checkout
    config config status.showUntrackedFiles no

    mkdir -p ~/.local/share
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.local/share
    git clone https://github.com/marlonrichert/zsh-autocomplete ~/.local/share

    # more minor things
    # just in case, conda should be installed already at that point
    # maybe put it in a clean enviroment at some point
    conda activate base 
    pip install neovim
    # use zsh
    chsh -s /usr/bin/zsh
    # install vim plug and the plugins
    sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
       https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
    nvim +PlugInstall +qall
    # kitty theme
    git clone --depth 1 git@github.com:dexpota/kitty-themes.git ~/.config/kitty/kitty-themes
}

install_fonts() {
    echo "Installing TUDo fons from the e5 wiki"
    echo "E5 user name:"
    read user
    echo "PW:"
    read pw
    curl -u $user:$pw https://wiki.e5.physik.tu-dortmund.de/pub/Main/TUFonts/TUDo_font_akkurat.zip -o TUDo_font_akkurat.zip
    mkdir -p $HOME/.local/share/fonts
    unzip TUDo_font_akkurat.zip -d $HOME/.local/share/fonts
    rm TUDo_font_akkurat.zip
}

install_packages(){
if [ -x "$(command -v apt-get)" ]
then
    sudo apt-get install --assume-yes $@
elif [ -x "$(command -v pacman)" ]
then
    sudo pacman -S --noconfirm  $@
elif [ -x "$(command -v yum)" ]
then
    sudo yum install -y $@
elif [ -x "$(command -v dnf)" ]
then
    sudo dnf install -y $@
elif [ -x "$(command -v emerge)" ]
then
    sudo emerge $@
elif [ -x "$(command -v zypper)" ]
then
    sudo zypper install -y $@
else
    echo "FAILED TO INSTALL PACKAGE: Package manager not found. You must manually install: $@">&2;
fi
}

install_manually() {
    # todo: make this automatic at least for manjaro
    echo "WARNING: You will need to install $1 manually. This is not implemented yet"
    echo "The package(s) might not be available for all distributions or named differently"
}

echo "This script is meant to collect some common setup steps. You can perform the steps individually or all at once.

DISCLAIMER:
- I usually run Manjaro, most tests are done on it (with AUR) enabled.
- For other distributions, some packages are not available (e.g. VSCode) and need to be installed by hand.
- I did some tests on Ubuntu-based distribution. Everything else is largely untested, but should in theory work
"

echo "
HOW TO USE THIS:
- These should be the steps https://toolbox.pep-dortmund.org/install/linux.html
- You will need a working internet connection and some steps will take a while, especially conda and TeXLive
- It runs mostly without any intervention. Exceptions: Git setup and TeXLive installation.
- Best execute this from the home folder, there might be some path assumptions left. I try to avoid it, but you know...
- Mamba will be installed in addition to conda to speed up the enviroment solving in the future. This is slow, dont panic
- VSCode is not directly available in most distributions (everything but arch?)
- The relevant toolbox settings end up in your ~/.bashrc. If you use a different shell, you need to copy them manually.
"
echo""


echo "What shall we do with our precious time?"
echo "
1: Toolbox workshop setup (2->3->4->5)
2: Toolbox packages only
3: Setup git
4: Conda only (slow)
5: TeXLive only (slooooooow)
6: Add LaTeX-themes (only tested in combination with 4)
7: My packages only (remember to install the missing packages by hand!)
8: My configs only (Remember to copy your ssh keys and passwords first, future me.)
9: My complete setup (Equal to 4->5->6->7->8)
"

read -p "Select the step to perform:" answer
case ${answer:0:1} in
    1)
        install_packages $common_minimal_packages
        install_packages $manual_minimal_packages || install_manually $manual_minimal_packages
        configure_git
        install_conda
        install_texlive
        echo "Install VSCode if needed and install the latex extension"
        ;;
    2)
        install_packages $common_minimal_packages
        install_packages $manual_minimal_packages || install_manually $manual_minimal_packages
        ;;
    3)  
        configure_git
        ;;
    4)
        install_conda
        ;;
    5)  
        install_texlive
        ;;
    6)  
        add_tex_themes
        ;;
    7)
        install_packages $common_minimal_packages
        install_packages $common_extra_packages
        install_manually $manual_minimal_packages
        install_manually $manual_extra_packages
        ;;     
    8)  
        setup_configs
        ;;
    9)  
        install_packages $common_minimal_packages
        install_packages $common_extra_packages
        install_packages $manual_minimal_packages || install_manually $manual_minimal_packages
        install_packages $manual_extra_packages || install_manually $manual_extra_packages
        install_conda
        install_texlive
        add_tex_themes
        setup_configs
        install_fonts
        ToDo
        ;;  
    *)
        echo "Invalid answer, exiting."
        exit 1
        ;;
esac
