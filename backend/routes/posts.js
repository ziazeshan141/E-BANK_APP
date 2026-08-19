/*
 * License: The MIT License (MIT)
 * Author:E-bank IT team
 * Author email: @ebanka-it.com
 * Date: Fri Aug 23 2019
 * Description: 
 * Main user back-end utility payment handler.
 * Implemented following methods:
 * 1. PUT for editing exsisting util payment
 * 2. GET by id util payment
 * 3. GET all util payments
 * 4. Multer storage handler to store util bill picture on server
 */
const express = require("express");
const multer = require("multer");
const Post = require("../models/post"); 
const checkAuth = require('../middleware/check-auth'); 
const router = express.Router();

const MIME_TYPE_MAP = {
  'image/png' : 'png',
  'image/jpg' : 'jpg',
  'image/jpeg' : 'jpg'
}

const storage = multer.diskStorage({ 
  destination: (req, file, cb) => { 
    const isValid = MIME_TYPE_MAP[file.mimetype]; 
    let error = new Error('Invalid MIME type!');
    if (isValid) {
      error = null;
    }
    cb(error,'backend/images'); 
  },
  filename: (req, file, cb) => {
    const name = file.originalname.toLowerCase().split(' ').join('-'); 
    const ext = MIME_TYPE_MAP[file.mimetype];
    cb(null, name + '-' + Date.now() + '.' + ext); 
  }
});

router.put('/:id', checkAuth, multer({storage: storage}).single('image'), (req, res, next) => {
  let imagePath = req.body.imagePath;

  if (req.file) {
    const url = req.protocol + '://' + req.get('host');
    imagePath = url + '/images/' + req.file.filename;
  }

  const post = new Post({
    _id: req.body.id,
    title: req.body.title,
    content: req.body.content,
    imagePath: imagePath
  });

  Post.updateOne(
    {
      _id: req.params.id,
      creator: req.userData.userId
    },
    post
  ).then(result => {
    if (result.matchedCount > 0) {
      res.status(200).json({
        message: 'Successfull change of util payment!'
      });
    } else {
      res.status(401).json({
        message: 'User not autorized!'
      });
    }
  }).catch(err => {
    res.status(500).json({
      error: err
    });
  });
});

router.delete("/:id", checkAuth, (req, res, next) => {
  const usID = req.userData.userId;

  Post.deleteOne({
    _id: req.params.id,
    creator: usID
  }).then(result => {
    if (result.deletedCount > 0) {
      res.status(200).json({
        message: 'Util payment deleted!'
      });
    } else {
      res.status(401).json({
        message: 'User not autorized!'
      });
    }
  }).catch(err => {
    res.status(500).json({
      error: err
    });
  });
});module.exports = router;
