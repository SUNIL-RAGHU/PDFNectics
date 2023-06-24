const express = require('express');
const multer = require('multer');
const fs = require('fs');
const path = require('path');

const { promisify } = require('util');
const { PDFDocument} = require('pdf-lib');
var convertapi = require('convertapi')('<Enter the Api Key here>');
const app = express();
const libre = require('libreoffice-convert');
libre.convertAsync = require('util').promisify(libre.convert);
const writeFileAsync = promisify(fs.writeFile);
const uploadDirectory = './uploads';


if (!fs.existsSync(uploadDirectory)) {
  fs.mkdirSync(uploadDirectory);
}

const upload = multer({
  storage: multer.diskStorage({
    destination: 'uploads/',
    filename: (req, file, cb) => {
      const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1e9);
      cb(null, 'uploaded-' + uniqueSuffix + getFileExtension(file));
    },
  }),
  fileFilter: (req, file, cb) => {
    const allowedMimeTypes = ['application/pdf', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'];
    if (allowedMimeTypes.includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(new Error('Only PDF and DOCX files are allowed.'), false);
    }
  },
});

function getFileExtension(file) {
  // Extracts the file extension from the originalname field
  const originalName = file.originalname;
  const extension = originalName.substring(originalName.lastIndexOf('.'));
  return extension;
}

class PDFProcessor {

  async mergePDFs(inputPaths, outputPath) {
    try {
      const mergedPdf = await PDFDocument.create();
      for (const inputPath of inputPaths) {
        const pdfBytes = await fs.promises.readFile(inputPath);
        const pdf = await PDFDocument.load(pdfBytes);
        const pages = await mergedPdf.copyPages(pdf, pdf.getPageIndices());
        pages.forEach((page) => mergedPdf.addPage(page));
      }
      const mergedPdfBytes = await mergedPdf.save();
      await fs.promises.writeFile(outputPath, mergedPdfBytes);
      return Promise.resolve();
    } catch (error) {
      return Promise.reject(error);
    }
  }
  async splitPDF(inputPath, startPage, endPage, outputDirectory) {
    try {
      const pdfBytes = await fs.promises.readFile(inputPath);
      const pdf = await PDFDocument.load(pdfBytes);

      const outputPath = path.join(outputDirectory, 'split.pdf');
      const splitPdf = await PDFDocument.create();

      for (let pageNumber = startPage; pageNumber <= endPage; pageNumber++) {
        const [copiedPage] = await splitPdf.copyPages(pdf, [pageNumber - 1]);
        splitPdf.addPage(copiedPage);
      }
      const splitPdfBytes = await splitPdf.save();
      await fs.promises.writeFile(outputPath, splitPdfBytes);
      return outputPath;
    } catch (error) {
      throw error;
    }
  }
  async compressedPdf(inputPath, outputDirectory, level) {
    try {
      const outputPath = path.join(outputDirectory, 'Compress.pdf');
      await convertapi.convert('compress', { File: inputPath, Presets: level }, 'pdf').then(async function(result) {
        return await result.saveFiles(outputPath);
      });
    } catch (error) {
      throw error;
    }
  }
  async  convertPdfToDoc(inputPath, outputDirectory) {
    try {
      const outputPath = path.join(outputDirectory, 'document.docx');
      const result = await convertapi.convert('docx', { File: inputPath }, 'pdf');
      await result.saveFiles(outputPath);
      return outputPath;
    } catch (error) {
      throw error;
    }
  }

  async  convertDocToPdf(inputPath, outputDirectory) {
    try {
      const outputPath = path.join(outputDirectory, 'converted.pdf');
      const result = await convertapi.convert('pdf', { File: inputPath }, 'docx');
      await result.saveFiles(outputPath);
      return outputPath;
    } catch (error) {
      throw error;
    }
  }
  
  

}

const pdfProcessor = new PDFProcessor();

async function cleanupFiles(files) {
  try {
    await Promise.all(
      files.map((file) =>
        fs.promises.unlink(file.path).then(() => {
          console.log(`Deleted file: ${file.path}`);
        })
      )
    );
  } catch (error) {
    console.error(`Failed to delete file: ${error.path}`);
    throw error;
  }
}

app.post('/api/merge', upload.array('files'), async (req, res) => {
  try {
    console.log(upload.files);
    const { files } = req;
    const inputPaths = files.map((file) => file.path);
    const outputPath = './uploads/merged.pdf';

    await pdfProcessor.mergePDFs(inputPaths, outputPath);
    const mergedPdf = fs.readFileSync(outputPath);

    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader('Content-Disposition', 'attachment; filename=merged.pdf');
    res.status(200);
    res.send(mergedPdf);

    await cleanupFiles(files.concat({ path: outputPath }));
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'An error occurred during PDF merge.' });
  }
});

app.post('/api/split', upload.single('file'), async (req, res) => {
  try {
    const { file } = req;
    const { startPage, endPage } = req.body;
    const inputPath = file.path;
    const outputDirectory = './uploads';
    const outputPath = await  pdfProcessor.splitPDF(
      inputPath,
      parseInt(startPage),
      parseInt(endPage),
      outputDirectory
    );

    const splitPdf = fs.readFileSync(outputPath);
    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader('Content-Disposition', `attachment; filename=${path.basename(outputPath)}`);
    res.status(200);
    res.send(splitPdf);

    await cleanupFiles([file, { path: outputPath }]);
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'An error occurred during PDF split.' });
  }
});

app.post('/api/compress', upload.single('file'), async (req, res) => {
  try {
    const { file } = req;
    const { compressionLevel } = req.body;
    let level = "";

    if (compressionLevel === 'Low') {
      level = 'text';
    } else if (compressionLevel === 'Medium') {
      level = 'archive';
    } else {
      level = 'web';
    }
    const inputPath = file.path;
    const outputPath = './uploads';

    await pdfProcessor.compressedPdf(inputPath, outputPath, level);

    const compressPdfPath = path.join(outputPath, 'compress.pdf');
    const compressPdf = fs.readFileSync(compressPdfPath);
    
    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader('Content-Disposition', 'attachment; filename=compressed.pdf');
    res.status(200).send(compressPdf);

    fs.unlink(inputPath, function(err) {
      if (err) {
        console.error('Error while deleting input file:', err);
      }
    });
    fs.unlink(compressPdfPath, function(err) {
      if (err) {
        console.error('Error while deleting output file:', err);
      }
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'An error occurred during PDF compression.' });
  }
});


app.post('/api/pdftodocx', upload.single('file'), async (req, res) => {
  try {
    const { file } = req;

    const inputPath = file.path;
    const outputPath = './uploads';

    await pdfProcessor.convertPdfToDoc(inputPath, outputPath);

    const documentPdfPath = path.join(outputPath, 'document.docx');
    const documentPdf = fs.readFileSync(documentPdfPath);
    
    res.setHeader('Content-Type', 'application/docx');
    res.setHeader('Content-Disposition', 'attachment; filename=document.docx');
    res.status(200).send(documentPdf);

    fs.unlink(inputPath, function(err) {
      if (err) {
        console.error('Error while deleting input file:', err);
      }
    });
    fs.unlink(compressPdfPath, function(err) {
      if (err) {
        console.error('Error while deleting output file:', err);
      }
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'An error occurred during PDF compression.' });
  }
});


app.post('/api/docxtopdf', upload.single('file'), async (req, res) => {
  try {
    const { file } = req;

    const inputPath = file.path;
    const outputPath = './uploads';

    await pdfProcessor.convertDocToPdf(inputPath, outputPath);

    const documentPdfPath = path.join(outputPath, 'converted.pdf');
    const documentPdf = fs.readFileSync(documentPdfPath);
    
    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader('Content-Disposition', 'attachment; filename=converted.pdf');
    res.status(200).send(documentPdf);

    fs.unlink(inputPath, function(err) {
      if (err) {
        console.error('Error while deleting input file:', err);
      }
    });
    fs.unlink(compressPdfPath, function(err) {
      if (err) {
        console.error('Error while deleting output file:', err);
      }
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'An error occurred during PDF compression.' });
  }
});


app.listen(3000, () => {
  console.log('Server is running on port 3000');
  console.log();
});
