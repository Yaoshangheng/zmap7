report_this_filefun(mfilename('fullpath'));

clf
set(gca,'visible','off');

txt4 = text(...
    'Color',[0 0 0 ],...
    'EraseMode','normal',...
    'Position',[0.15 0.54 0 ],...
    'Rotation',0 ,...
    'FontSize',16 ,...
    'String', 'Select the centerpoint  on the map');

he = gcf
figure_w_normalized_uicontrolunits(1)
set(gcf,'Pointer','watch')
pause(0.1)
circle