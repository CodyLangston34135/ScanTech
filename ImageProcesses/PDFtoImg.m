function images = PDFtoImg(pdfFile)
    % Import pdf loaders
    import org.apache.pdfbox.*
    import java.io.*

    % Read pdf file
    % filename = fullfile(pwd,pdfFile);
    filename = pdfFile;
    jFile = File(filename);
    document = pdmodel.PDDocument.load(jFile);

    % Render pdf into pixels
    pdfRenderer = rendering.PDFRenderer(document);
    count = document.getNumberOfPages();

    % Loop through page count and store images as png
    images = [];
    f = waitbar(0,'Importing answer sheets');
    for ii = 1:count
        bim = pdfRenderer.renderImageWithDPI(ii-1, 300, rendering.ImageType.RGB);
    
        % Save with 3 digits so alphabetical order works, Can be done with
        % sprintf(%03d) but doesnt work sometimes so this is brute force
        if ii <10
            images = [images (filename + "-" +"Page00" + ii + ".png")];
            tools.imageio.ImageIOUtil.writeImage(bim, filename + "-" +"Page00" + ii + ".png", 300);
        elseif ii <100
                    images = [images (filename + "-" +"Page0" + ii + ".png")];
            tools.imageio.ImageIOUtil.writeImage(bim, filename + "-" +"Page0" + ii + ".png", 300);
        else
            images = [images (filename + "-" +"Page" + ii + ".png")];
            tools.imageio.ImageIOUtil.writeImage(bim, filename + "-" +"Page" + ii + ".png", 300);
        end
    
        waitbar(ii/count,f,'Importing answer sheets')
    end
    close(f)
    document.close()
end