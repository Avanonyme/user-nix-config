{ vm, ... }:
{
  vm.vm-ui.provides = {
    gui.includes = [
      vm.vm-ui
      vm.vm-bootable._.gui
      vm.xfce-desktop
    ];

    tui.includes = [
      vm.vm-ui
      vm.vm-bootable._.tui
    ];
  };
}
