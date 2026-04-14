#!/usr/bin/env node

/**
 * 拆分 Swagger 文档为用户端和管理端两份
 * 用法: node scripts/split-swagger.js
 */

const fs = require('fs');
const path = require('path');

const docsDir = path.join(__dirname, '../docs');
const sourceFile = path.join(docsDir, 'swagger.json');
const userFile = path.join(docsDir, 'swagger-user.json');
const adminFile = path.join(docsDir, 'swagger-admin.json');

// 读取原始文档
const swagger = JSON.parse(fs.readFileSync(sourceFile, 'utf8'));

// 创建用户端文档（移除 definitions/components）
const userSwagger = {
  swagger: swagger.swagger,
  info: {
    ...swagger.info,
    title: swagger.info.title + ' - 用户端接口',
    description: '用户端 API 文档'
  },
  host: swagger.host,
  basePath: swagger.basePath,
  schemes: swagger.schemes,
  paths: {},
  tags: [],
  securityDefinitions: swagger.securityDefinitions
};

// 创建管理端文档（移除 definitions/components）
const adminSwagger = {
  swagger: swagger.swagger,
  info: {
    ...swagger.info,
    title: swagger.info.title + ' - 管理端接口',
    description: '管理端 API 文档'
  },
  host: swagger.host,
  basePath: swagger.basePath,
  schemes: swagger.schemes,
  paths: {},
  tags: [],
  securityDefinitions: swagger.securityDefinitions
};

// 用户端 Tag 前缀
const userTagPrefixes = ['User'];

// 分类 paths
for (const [path, methods] of Object.entries(swagger.paths)) {
  for (const [method, spec] of Object.entries(methods)) {
    if (!spec.tags || spec.tags.length === 0) continue;
    
    const isUserApi = spec.tags.some(tag => 
      userTagPrefixes.some(prefix => tag.startsWith(prefix))
    );
    
    if (isUserApi) {
      if (!userSwagger.paths[path]) userSwagger.paths[path] = {};
      userSwagger.paths[path][method] = spec;
    } else {
      if (!adminSwagger.paths[path]) adminSwagger.paths[path] = {};
      adminSwagger.paths[path][method] = spec;
    }
  }
}

// 分类 tags
if (swagger.tags) {
  swagger.tags.forEach(tag => {
    const isUserTag = userTagPrefixes.some(prefix => tag.name.startsWith(prefix));
    if (isUserTag) {
      userSwagger.tags.push(tag);
    } else {
      adminSwagger.tags.push(tag);
    }
  });
}

// 写入文件
fs.writeFileSync(userFile, JSON.stringify(userSwagger, null, 2), 'utf8');
fs.writeFileSync(adminFile, JSON.stringify(adminSwagger, null, 2), 'utf8');

console.log('✅ Swagger 文档拆分完成:');
console.log(`   用户端: ${userFile}`);
console.log(`   管理端: ${adminFile}`);
console.log(`   用户端接口数: ${Object.keys(userSwagger.paths).length}`);
console.log(`   管理端接口数: ${Object.keys(adminSwagger.paths).length}`);
